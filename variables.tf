variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "env_id" {
  description = "Unique environment identifier"
}

variable "key_name" {
  description = "AWS key pair name for SSH access"
}

variable "vpc_id" {
  description = "VPC ID where the instance will be launched"
}
