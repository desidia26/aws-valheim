module "bot_lambda" {
  source             = "./discord-lambda"
  role_arn           = aws_iam_role.iam_for_lambda.arn
  env = {
    DOMAIN       = "${var.domain}"
    DISCORD_KEY  = "${var.discord_public_key}"
    SERVICE_ARN  = "${aws_ecs_service.valheim_service.id}"
    CLUSTER_NAME = "${aws_ecs_cluster.valheim_server_cluster.id}"
    REGION       = "${data.aws_region.current.name}"
  }
}

module "nightly_lambda" {
  source           = "./nightly-lambda"
  role_arn         = aws_iam_role.iam_for_lambda.arn
  env = {
    WEBHOOK      = "${data.aws_ssm_parameter.discord_webhook.value}"
    DOMAIN       = "${var.domain}"
    ZONE_ID      = "${data.aws_route53_zone.valheim_domain.zone_id}"
    SERVICE_ARN  = "${aws_ecs_service.valheim_service.id}"
    CLUSTER_NAME = "${aws_ecs_cluster.valheim_server_cluster.id}"
    REGION       = "${data.aws_region.current.name}"
  }
}

module "ip_lambda" {
  source           = "./update-r53-lambda"
  role_arn         = aws_iam_role.iam_for_lambda.arn
  env = {
    DOMAIN       = "${var.domain}"
    CLUSTER_NAME = "${aws_ecs_cluster.valheim_server_cluster.id}"
    REGION       = "${data.aws_region.current.name}"
    ZONE_ID      = "${data.aws_route53_zone.valheim_domain.zone_id}"
  }
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
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "route53:ChangeResourceRecordSets"
        ],
        Effect : "Allow",
        Resource : [
          "${aws_ecs_service.valheim_service.id}",
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:container-instance/*/*",
          "arn:aws:ecs:*:${data.aws_caller_identity.current.account_id}:task/*/*",
          "${data.aws_route53_zone.valheim_domain.arn}"
        ]
      },
      {
        Action : [
          "ec2:DescribeNetworkInterfaces"
        ],
        Effect : "Allow",
        Resource: "*"
      },
      {
        Action : [
          "ecs:ListTasks"
        ],
        Effect : "Allow",
        Resource: "*"
      },
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