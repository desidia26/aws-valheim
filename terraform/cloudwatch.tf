resource "aws_cloudwatch_log_group" "services_log_group" {
  name = "${terraform.workspace}-valheim-server-logs"
}