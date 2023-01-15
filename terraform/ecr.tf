resource "null_resource" "push_images" {
  triggers = {
    timestamp = var.build_image ? timestamp() : "foo"
  }

  provisioner "local-exec" {
    command = "/bin/bash ${path.module}./valheim/dockerPush.sh ${data.aws_ecr_repository.valheim_server.repository_url} ${var.valheim_tag}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "/bin/bash -c echo \"no-op\""
  }
  depends_on = [data.aws_ecr_repository.valheim_server]
}