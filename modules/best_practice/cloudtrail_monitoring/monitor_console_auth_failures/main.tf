# Implements AWS CIS Foundations Benchmark 3.6
resource "aws_cloudwatch_log_metric_filter" "console_auth_failures" {
  name  = "DD_BP_MetricFilter_Console_Auth_Failures"
  count = "${var.enable}"

  pattern = <<PATTERN
{
  ($.eventName = "ConsoleLogin") && ($.errorMessage = "Failed authentication") 
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "Console_Auth_Failures"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_auth_failures" {
  count               = "${var.enable}"
  alarm_name          = "DD_BP_Alarm_Console_Auth_Failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Console_Auth_Failures"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of console authentication failures."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
