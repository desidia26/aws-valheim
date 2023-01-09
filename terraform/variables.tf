variable "discord_webhook_url" {
  type        = string
  default     = ""
  description = "Webhook URL to send notifications to."
}

variable "domain" {
  type        = string
  default     = ""
  description = "Main domain for server"
}

variable "valheim_tag" {
  type    = string
  default = "latest"
}

variable "server_pass" {
  type    = string
  default = "262626"
}

variable "webhook_ssm_name" {
  type        = string
  default     = "valheim_webhook_url"
  description = "name of the ssm param storing the webhook url"
}

variable "ecr_name" {
  type    = string
  default = "valheim_server"
}

variable "volume_name" {
  type = string
  default = "valheim-config-volume"
}

variable "valheim_bucket" {
  type = string
  default = "valheim-state"
}

variable "world_name" {
  type = string
  default = "AWholeNewWorld"
}