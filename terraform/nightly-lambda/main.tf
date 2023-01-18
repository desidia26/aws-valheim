locals {
  script_name = "valheim-nightly-lambda"
}

module "discord_lambda" {
  source      = "../shared/go-lambda"
  go_dir      = "${path.module}/go"
  script_name = local.script_name
  role_arn    = var.role_arn
  lambda_env  = var.env
}

// Allow CloudWatch to invoke our function
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke" {
  function_name = module.discord_lambda.function_name
  statement_id = "CloudWatchInvoke"
  action = "lambda:InvokeFunction"

  source_arn = aws_cloudwatch_event_rule.nightly_rule.arn
  principal = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "nightly_rule" {
  name                = "nightly_rule"
  schedule_expression = "cron(0 7 * * ? *)"
}

resource "aws_cloudwatch_event_target" "nightly_task" {
  rule      = aws_cloudwatch_event_rule.nightly_rule.name
  target_id = "nightly_task"
  arn       = module.discord_lambda.arn
}