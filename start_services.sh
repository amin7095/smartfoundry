#!/bin/bash
cd /opt/on-demand-env
docker-compose up -d --build
/opt/on-demand-env/mockserver_init.sh || true
