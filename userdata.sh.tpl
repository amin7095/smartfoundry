#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

ENV_NAME="${env_name}"
DD_API_KEY="${datadog_api_key}"
GREMLIN_TEAM_ID="${gremlin_team_id}"
GREMLIN_SECRET="${gremlin_secret}"
APP_REPO="${app_repo}"
APP_BRANCH="${app_branch}"
PAYMENT_MODE="${payment_mode}"
DB_USER="${db_username}"
DB_PASS="${db_password}"
DDB_TABLE="${dynamodb_table_name}"
AWS_REGION="${aws_region}"

LOGFILE="/var/log/on_demand_bootstrap.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "[BOOT] Starting bootstrap for ${ENV_NAME} at $(date)"

apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release git jq python3-pip

# Docker
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  usermod -aG docker ubuntu || true
fi

# docker-compose
if ! command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_VERSION="1.29.2"
  curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

WORKDIR="/opt/on-demand-env"
mkdir -p ${WORKDIR}
cd ${WORKDIR}

# create docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: "3.7"
services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASS}
      POSTGRES_DB: bankdb
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - onnet

  app:
    build:
      context: ./app
      dockerfile: Dockerfile
    environment:
      DATABASE_URL: "postgresql://${DB_USER}:${DB_PASS}@postgres:5432/bankdb"
      FLASK_ENV: production
      PAYMENT_GATEWAY_URL: "http://mockserver:1080"
    depends_on:
      - postgres
    networks:
      - onnet
    ports:
      - "5000:5000"

  nginx:
    image: nginx:stable
    depends_on:
      - app
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "80:80"
    networks:
      - onnet

  mockserver:
    image: jamesdbloom/mockserver:mockserver-5.11.2
    container_name: mockserver
    ports:
      - "1080:1080"
    networks:
      - onnet

  seeder:
    image: python:3.10-slim
    volumes:
      - ./seeder:/seeder
    depends_on:
      - postgres
      - mockserver
    entrypoint: ["bash", "-c", "python3 /seeder/seed_from_dynamo.py --target postgresql://${DB_USER}:${DB_PASS}@postgres:5432/bankdb --env ${ENV_NAME}"]
volumes:
  pgdata:
networks:
  onnet:
EOF