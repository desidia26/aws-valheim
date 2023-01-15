locals {
  script_name = "valheim-discord-lambda"
}

module "discord_lambda" {
  source = "../shared/go-lambda"
  go_dir = "${path.module}/go"
  script_name = local.script_name
  role_arn = var.role_arn
  lambda_env = {
    DISCORD_KEY  = "${var.discord_public_key}"
    SERVICE_ARN  = "${var.ecs_service_arn}"
    CLUSTER_NAME = "${var.ecs_cluster_name}"
    REGION       = "${var.aws_region}"
  }
}

resource "aws_api_gateway_rest_api" "valheim_discord_api" {
  name = "valheim-discord-api"
}

resource "aws_api_gateway_method" "valheim_gateway_method" {
  rest_api_id   = aws_api_gateway_rest_api.valheim_discord_api.id
  resource_id   = aws_api_gateway_rest_api.valheim_discord_api.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.valheim_discord_api.id
  resource_id             = aws_api_gateway_rest_api.valheim_discord_api.root_resource_id
  http_method             = aws_api_gateway_method.valheim_gateway_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.discord_lambda.function_invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.discord_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.valheim_discord_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "valheim_gateway_deployment" {
  depends_on = [aws_api_gateway_integration.integration]

  rest_api_id = aws_api_gateway_rest_api.valheim_discord_api.id
  stage_name  = "v1"
}

output "url" {
  value = aws_api_gateway_deployment.valheim_gateway_deployment.invoke_url
}
