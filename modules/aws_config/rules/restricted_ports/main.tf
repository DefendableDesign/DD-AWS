resource "aws_config_config_rule" "r" {
  name = "DD_Config_EC2_OpenPorts"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = "${aws_lambda_function.lf_configrule.arn}"
    source_detail = {
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }

  input_parameters = <<JSON
{
    "sqsUrl":"${var.remediation_queue_url}",
    "prohibitedPorts":"${var.prohibited_ports}"
}
JSON

  count = "${var.config_is_setup}"
}
