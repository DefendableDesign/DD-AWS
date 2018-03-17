# Implements AWS CIS Foundations Benchmark 3.2
resource "aws_cloudwatch_log_metric_filter" "console_sign_in_without_mfa" {
  name = "DD_BP_MetricFilter_Console_Sign_In_Without_MFA"

  pattern = <<PATTERN
{
    ($.eventName = "ConsoleLogin") && ($.additionalEventData.MFAUsed != "Yes") 
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "Console_Sign_In_Without_MFA"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "console_sign_in_without_mfa" {
  alarm_name          = "DD_BP_Alarm_Console_Sign_In_Without_MFA"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Console_Sign_In_Without_MFA"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number console sign ins that occur without MFA."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
