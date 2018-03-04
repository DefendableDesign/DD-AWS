variable "config_is_setup" {
  default = "0"
}

variable "temp_dir" {
  default = "/tmp"
}

variable "remediation_queue_url" {}
variable "remediation_queue_arn" {}

variable "remediation_coordinator_lambda_arn" {}