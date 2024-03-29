resource "aws_ecs_cluster" "valheim_server_cluster" {
  name       = "${terraform.workspace}-valheim-server"
  depends_on = [null_resource.push_images]
}

resource "aws_ecs_task_definition" "valheim_task" {
  family                   = "${terraform.workspace}-valheim"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 8192
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions    = <<DEFINITION
[
  {
    "image": "${data.aws_ecr_repository.valheim_server.repository_url}:${var.valheim_tag}",
    "cpu": 1024,
    "memory": 4096,
    "name": "valheim",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 2456,
        "hostPort": 2456,
        "protocol": "udp"
      },
      {
        "containerPort": 2457,
        "hostPort": 2457,
        "protocol": "udp"
      },
      {
        "containerPort": 80,
        "hostPort": 80,
        "protocol": "http"
      }
    ],
    "environment": [
      {
        "name": "BACKUPS_CRON", 
        "value": "0 5 * * *"
      },
      {
        "name": "DISCORD_WEBHOOK", 
        "value": "${data.aws_ssm_parameter.discord_webhook.value}"
      },
      {
        "name": "IP_LAMBDA_FUNCTION_NAME", 
        "value": "${module.ip_lambda.function_name}"
      },
      {
        "name": "POST_BACKUP_HOOK", 
        "value": "uploadBackupToS3 @BACKUP_FILE@ $WORLD_BUCKET"
      },
      {
        "name": "POST_SERVER_LISTENING_HOOK", 
        "value": "notifiyDiscord \"Server now accepting connections at $URL!\""
      },
      {
        "name": "POST_SERVER_SHUTDOWN_HOOK", 
        "value": "notifiyDiscord \"R.I.P Server.\""
      },
      {
        "name": "PRE_BOOTSTRAP_HOOK", 
        "value": "printenv && worldInit $WORLD_BUCKET $WORLD_NAME && updateR53 $IP_LAMBDA_FUNCTION_NAME"
      },
      {
        "name": "PRE_SERVER_RUN_HOOK", 
        "value": "downloadMods && notifiyDiscord \"Server starting...\""
      },
      {
        "name": "PRE_RESTART_HOOK", 
        "value": "notifiyDiscord \"Restarting to apply update!\""
      },
      {
        "name": "PRE_SERVER_SHUTDOWN_HOOK", 
        "value": "notifiyDiscord \"Server shutting down...\""
      },
      {
        "name": "RESTART_CRON", 
        "value": "0 10 * * *"
      },
      {
        "name": "BEPINEX", 
        "value": "true"
      },
      {
        "name": "SERVER_PASS", 
        "value": "${var.server_pass}"
      },
      {
        "name": "STATUS_HTTP", 
        "value": "true"
      },
      {
        "name": "URL", 
        "value": "${var.domain}:2456"
      },
      {
        "name": "WORLD_BUCKET", 
        "value": "s3://${var.valheim_bucket}"
      },
      {
        "name": "WORLD_NAME", 
        "value": "${var.world_name}"
      }
    ],
    "mountPoints": [
      {
        "containerPath": "/config",
        "sourceVolume": "${var.volume_name}"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${terraform.workspace}-valheim-server-logs",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
DEFINITION

  volume {
    name = var.volume_name
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.valheim_config.id
    }
  }
  depends_on = [
    null_resource.push_images
  ]
}

resource "aws_ecs_service" "valheim_service" {
  name                               = "${terraform.workspace}-valheim_service"
  cluster                            = aws_ecs_cluster.valheim_server_cluster.id
  task_definition                    = aws_ecs_task_definition.valheim_task.arn
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  desired_count                      = 1
  launch_type                        = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.task_sg.id]
    subnets          = [aws_subnet.public.id]
    assign_public_ip = true
  }
  depends_on = [
    null_resource.push_images
  ]
}