data "aws_ami" "ubuntu" {
  most_recent = true
  filter { name = "name", values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"] }
  owners = ["099720109477"]
}

data "aws_caller_identity" "current" {}

resource "aws_instance" "host" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  tags = merge({
    Name        = "on-demand-${var.env_name}",
    Environment = var.env_name
  }, var.tags)

  user_data = templatefile("${path.module}/userdata.sh.tpl", {
    env_name = var.env_name,
    datadog_api_key = var.datadog_api_key,
    gremlin_team_id = var.gremlin_team_id,
    gremlin_secret = var.gremlin_secret,
    app_repo = var.app_repo,
    app_branch = var.app_branch,
    payment_mode = var.payment_mode,
    db_username = var.db_username,
    db_password = var.db_password,
    dynamodb_table_name = var.dynamodb_table_name,
    aws_region = var.aws_region
  })
}

resource "aws_iam_role" "ec2_role" {
  name = "on_demand_env_ec2_role_${replace(var.env_name, "[^\n\\w-]", "-")}"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals { type = "Service", identifiers = ["ec2.amazonaws.com"] }
  }
}

resource "aws_iam_role_policy" "ec2_policy" {
  role = aws_iam_role.ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Action = ["ssm:SendCommand","ssm:GetCommandInvocation","ssm:ListCommands"], Effect = "Allow", Resource = "*" },
      { Action = ["dynamodb:Query","dynamodb:GetItem","dynamodb:Scan"], Effect = "Allow", Resource = var.dynamodb_table_name != "" ? "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}" : "*" }
    ]
  })
}

output "app_ip" { value = aws_instance.host.public_ip }
output "instance_id" { value = aws_instance.host.id }
