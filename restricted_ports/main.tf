resource "aws_config_config_rule" "r" {
  name = "Check-EC2-OpenPorts"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = "${aws_lambda_function.lf.arn}"
    source_detail = {
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }

  input_parameters = <<JSON
{
    "sqsUrl":"${aws_sqs_queue.q.id}",
    "prohibitedPorts":"22,1433,3306,3389"
}
JSON

  count = "${var.config_is_setup}"
}

