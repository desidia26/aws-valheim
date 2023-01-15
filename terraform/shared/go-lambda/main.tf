variable "go_dir" {}
variable "script_name" {}
variable "lambda_env" {}
variable "role_arn" {}

resource "null_resource" "build" {
  triggers = {
    script_hash = "${sha256(file("${var.go_dir}/main.go"))}"
  }
  provisioner "local-exec" {
    working_dir = "${var.go_dir}"
    command     = "go build"
  }
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "${var.go_dir}/${var.script_name}"
  output_path = "${var.go_dir}/${var.script_name}.zip"
  depends_on = [
    null_resource.build
  ]
}

resource "aws_lambda_function" "go_lambda" {
  function_name    = var.script_name
  filename         = data.archive_file.zip.output_path
  handler          = var.script_name
  source_code_hash = data.archive_file.zip.output_base64sha256
  role             = var.role_arn
  runtime          = "go1.x"
  memory_size      = 128
  timeout          = 10
  environment {
    variables = var.lambda_env
  }
}

resource "aws_cloudwatch_log_group" "function_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.go_lambda.function_name}"
  retention_in_days = 7
  lifecycle {
    prevent_destroy = false
  }
}

output "function_invoke_arn" {
  value = aws_lambda_function.go_lambda.invoke_arn
}

output "function_name" {
  value = aws_lambda_function.go_lambda.function_name
}

output "arn" {
  value = aws_lambda_function.go_lambda.arn
}
