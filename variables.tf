variable "env_name" { type = string }
variable "aws_region" { type = string, default = "us-east-1" }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }
variable "instance_type" { type = string, default = "t3.medium" }
variable "ssh_public_key" { type = string }
variable "app_repo" { type = string, default = "none" }
variable "app_branch" { type = string, default = "main" }
variable "payment_mode" { type = string, default = "mock" }
variable "datadog_api_key" { type = string, sensitive = true }
variable "gremlin_team_id" { type = string, sensitive = true }
variable "gremlin_secret" { type = string, sensitive = true }
variable "db_username" { type = string, default = "demo" }
variable "db_password" { type = string, sensitive = true }
variable "dynamodb_table_name" { type = string, default = "" }
variable "tags" { type = map(string), default = {} }
