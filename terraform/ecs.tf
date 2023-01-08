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
        "containerPort": 9001,
        "hostPort": 9001,
        "protocol": "tcp"
      }
    ],
    "environment": [
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
    subnets          = [aws_subnet.public.id]
    assign_public_ip = true
  }
  service_registries {
    registry_arn = aws_service_discovery_service.valheim_service_discovery_service.arn
  }
  depends_on = [
    aws_service_discovery_service.valheim_service_discovery_service
  ]
}

resource "aws_service_discovery_public_dns_namespace" "service_namespace" {
  name        = var.domain
  description = "namespace for valheim"
}

resource "aws_service_discovery_service" "valheim_service_discovery_service" {
  name = "valheim"

  dns_config {
    namespace_id = aws_service_discovery_public_dns_namespace.service_namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 5
  }
}