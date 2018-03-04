resource "aws_cloudwatch_event_rule" "trigger_remediation" {
  name        = "DD_Config_EventRule_Remediation_Coordinator"
  description = "Periodically triggers the DD_Config_Remediation_Coordinator process."
  is_enabled  = "${var.enable_auto_response}"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lf" {
  rule      = "${aws_cloudwatch_event_rule.trigger_remediation.name}"
  target_id = "DD_Config_EventTarget_EC2_OpenPorts_Remediation"
  arn       = "${aws_lambda_function.lf_remediation_coordinator.arn}"
  input     = <<JSON
{
    "sqsUrl":"${var.remediation_queue_url}"
}
JSON
}
