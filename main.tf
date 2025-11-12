terraform {
  cloud {
    organization = "Smartfoundry-TES"
    workspaces {
      name = "Smartfoundry-Env"
    }
  }
}

provider "aws" {
  region = var.region
}

# Security Group for Banking App
resource "aws_security_group" "banking_sg" {
  name        = "banking-sg-${var.env_id}"
  description = "Allow HTTP, SSH, Prometheus"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Prometheus Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance for 3-Tier Banking App
resource "aws_instance" "banking_app" {
  ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = "t3.medium"
  key_name      = var.key_name
  security_groups = [aws_security_group.banking_sg.name]

  tags = {
    Name = "banking-app-${var.env_id}"
  }

  user_data = <<-EOF
    #!/bin/bash
    yum update -y

    # Web Tier
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd

    # DB Tier
    yum install -y mariadb-server
    systemctl start mariadb
    systemctl enable mariadb

    # App Tier
    yum install -y java-11-openjdk

    # Deploy Banking App placeholder
    echo "<h1>Banking App Running</h1>" > /var/www/html/index.html

    # Install Prometheus Node Exporter
    curl -LO https://github.com/prometheus/node_exporter/releases/latest/download/node_exporter.tar.gz
    tar xvf node_exporter.tar.gz
    ./node_exporter &

    # Install Gremlin Agent
    curl -s https://api.gremlin.com/install.sh | bash
  EOF
}

output "instance_public_ip" {
  value = aws_instance.banking_app.public_ip
}

output "prometheus_target" {
  value = "${aws_instance.banking_app.public_ip}:9100"
}
