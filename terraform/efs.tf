resource "aws_efs_file_system" "valheim_config" {}

resource "aws_efs_mount_target" "mount" {
  file_system_id  = aws_efs_file_system.valheim_config.id
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.task_sg.id]
}