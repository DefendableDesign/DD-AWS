resource "aws_config_config_rule" "r" {
  name = "DD_Config_S3_PublicAccess"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = "${aws_lambda_function.lf_configrule.arn}"
    source_detail = {
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  input_parameters = <<JSON
{
    "sqsUrl":"${var.remediation_queue_url}",
    "bucketWhitelist":""
}
JSON

  count = "${var.config_is_setup}"
}
