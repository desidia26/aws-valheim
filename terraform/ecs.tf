resource "aws_ecs_cluster" "valheim_server_cluster" {
  name       = "${terraform.workspace}-valheim-server"
  depends_on = [null_resource.push_images]
}

resource "aws_ecs_task_definition" "valheim_task" {
  family                   = "${terraform.workspace}-valheim"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = <<DEFINITION
[
  {
    "image": "${data.aws_ecr_repository.valheim_server.repository_url}:${var.valheim_tag}",
    "cpu": 2048,
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
        "name": "STATUS_HTTP", 
        "value": "true"
      },
      {
        "name": "SERVER_PASS", 
        "value": "${var.server_pass}"
      },
      {
        "name": "URL", 
        "value": "${var.domain}:2456"
      },
      {
        "name": "DISCORD_WEBHOOK", 
        "value": "${data.aws_ssm_parameter.discord_webhook.value}"
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
}

resource "aws_ecs_service" "valheim_service" {
  name            = "${terraform.workspace}-valheim_service"
  cluster         = aws_ecs_cluster.valheim_server_cluster.id
  task_definition = aws_ecs_task_definition.valheim_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    security_groups  = [aws_security_group.task_sg.id]
    subnets          = [aws_subnet.public[0].id, aws_subnet.public[1].id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.valheim_target_group.arn}" # Referencing our target group
    container_name   = "valheim"
    container_port   = 2456
  }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.status_target_group.arn}" # Referencing our target group
    container_name   = "valheim"
    container_port   = 80
  }
}