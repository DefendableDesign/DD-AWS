variable "config_is_setup" {
  default = "0"
}

variable "prohibited_ports" {
  default = "22,3389"
}

variable "temp_dir" {
  default = "/tmp"
}

variable "remediation_queue_url" {}
variable "remediation_queue_arn" {}