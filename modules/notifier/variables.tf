variable "slack_webhook_url" {
  default = ""
}

variable "slack_channel" {
  default = ""
}

variable "temp_dir" {
  default = "/tmp"
}

variable "kms_key_id" {}
variable "kms_arn" {}
variable "monitoring_sns_arn" {}
variable "config_sns_arn" {}
