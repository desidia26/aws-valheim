locals {
  script_name = "valheim-discord-lambda"
}

resource "null_resource" "build" {
  triggers = {
    script_hash = "${sha256(file("${path.module}/go/main.go"))}"
  }
  provisioner "local-exec" {
    working_dir = "${path.module}/go"
    command = "go build"
  }
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "${path.module}/go/${local.script_name}"
  output_path = "${path.module}/${local.script_name}.zip"
  depends_on = [
    null_resource.build
  ]
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "valheim_discord" {
  function_name    = "valheim_discord"
  filename         = "${local.script_name}.zip"
  handler          = "${local.script_name}"
  source_code_hash = "${data.archive_file.zip.output_base64sha256}"
  role             = "${aws_iam_role.iam_for_lambda.arn}"
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 10
}

resource "aws_api_gateway_rest_api" "valheim_discord_api" {
  name = "valheim-discord-api"
}


resource "aws_api_gateway_method" "valheim_gateway_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.valheim_discord_api.id}"
  resource_id   = "${aws_api_gateway_rest_api.valheim_discord_api.root_resource_id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.valheim_discord_api.id}"
  resource_id             = "${aws_api_gateway_rest_api.valheim_discord_api.root_resource_id}"
  http_method             = "${aws_api_gateway_method.valheim_gateway_method.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.valheim_discord.invoke_arn}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.valheim_discord.function_name}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.valheim_discord_api.execution_arn}/*/*/*"
}

resource "aws_api_gateway_deployment" "valheim_gateway_deployment" {
  depends_on = [aws_api_gateway_integration.integration]

  rest_api_id = "${aws_api_gateway_rest_api.valheim_discord_api.id}"
  stage_name  = "v1"

}

output "url" {
  value = "${aws_api_gateway_deployment.valheim_gateway_deployment.invoke_url}"
}