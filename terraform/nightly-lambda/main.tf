locals {
  script_name = "valheim-nightly-lambda"
}

module "discord_lambda" {
  source = "../shared/go-lambda"
  go_dir = "${path.module}/go"
  script_name = local.script_name
  role_arn = var.role_arn
  lambda_env = {
    WEBHOOK      = "${var.webhook}"
    DOMAIN       = "${var.domain}"
    SERVICE_ARN  = "${var.ecs_service_arn}"
    CLUSTER_NAME = "${var.ecs_cluster_name}"
    REGION       = "${var.aws_region}"
  }
}
resource "aws_cloudwatch_event_rule" "nightly_rule" {
  name = "nightly_rule"
  schedule_expression = "cron(0 2 * * ? *)"
}

resource "aws_cloudwatch_event_target" "nightly_task" {
  rule = aws_cloudwatch_event_rule.nightly_rule.name
  target_id = "nightly_task"
  arn = module.discord_lambda.arn
}