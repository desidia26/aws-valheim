module "bot_lambda" {
  source             = "./discord-lambda"
  discord_public_key = var.discord_public_key
  ecs_service_arn    = aws_ecs_service.valheim_service.id
  ecs_cluster_name   = aws_ecs_cluster.valheim_server_cluster.id
  aws_region         = data.aws_region.current.name
  role_arn           = aws_iam_role.iam_for_lambda.arn
}

module "nightly_lambda" {
  source = "./nightly-lambda"
  ecs_service_arn    = aws_ecs_service.valheim_service.id
  ecs_cluster_name   = aws_ecs_cluster.valheim_server_cluster.id
  aws_region         = data.aws_region.current.name
  domain             = var.domain
  role_arn           = aws_iam_role.iam_for_lambda.arn
  webhook            = data.aws_ssm_parameter.discord_webhook.value
}


resource "aws_iam_role" "iam_for_lambda" {
  name = "lambda_role"

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

resource "aws_iam_policy" "function_policy" {
  name = "function-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect : "Allow",
        Resource : "arn:aws:logs:*:*:*"
      },
      {
        Action : [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        Effect : "Allow",
        Resource : "${aws_ecs_service.valheim_service.id}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.iam_for_lambda.id
  policy_arn = aws_iam_policy.function_policy.arn
  depends_on = [
    aws_iam_policy.function_policy
  ]
}