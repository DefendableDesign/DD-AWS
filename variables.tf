variable "region" {
  default = "ap-southeast-2"
}

variable "enable_auto_response" {
  default = "false"
}

variable "slack_webhook_url" {
  default = ""
}

variable "slack_channel" {
  default = ""
}

variable "enable_cis_level_2_alerts" {
  default = "true"
}
