variable "config_is_setup" {
  default = "0"
}

variable "prohibited_ports" {
  default = "22,3389"
}

variable "enable_auto_response" {
  default = "false"
}

variable "temp_dir" {
  default = "/tmp"
}
