locals {
  script_name = "valheim-update-r53-lambda"
}

module "ip_lambda" {
  source      = "../shared/go-lambda"
  go_dir      = "${path.module}/go"
  script_name = local.script_name
  role_arn    = var.role_arn
  lambda_env  = var.env
}

output "function_name" {
  value = module.ip_lambda.function_name
}