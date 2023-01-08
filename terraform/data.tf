data "aws_ssm_parameter" "discord_webhook" {
  name = var.webhook_ssm_name
}

data "aws_ecr_repository" "valheim_server" {
  name = var.ecr_name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}