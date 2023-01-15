module "bot_lambda" {
  source = "./discord-lambda"
  discord_public_key = "${var.discord_public_key}"
  ecs_service_arn = aws_ecs_service.valheim_service.id
  ecs_cluster_name = aws_ecs_cluster.valheim_server_cluster.id
  aws_region = data.aws_region.current.name
}