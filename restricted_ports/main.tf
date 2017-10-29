resource "aws_config_config_rule" "r" {
  name = "Check-EC2-OpenPorts"

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }

  input_parameters = <<JSON
{
    "blockedPort1":"3389",
    "blockedPort2":"22",
    "blockedPort3":"21",
    "blockedPort4":"1433",
    "blockedPort5":"3306"
}
JSON

  count = "${var.config_is_setup}"
}

