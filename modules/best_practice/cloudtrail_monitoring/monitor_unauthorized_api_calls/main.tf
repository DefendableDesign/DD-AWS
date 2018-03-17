# Implements AWS CIS Foundations Benchmark 3.1
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name = "DD_BP_MetricFilter_Unauthorized_API_Calls"

  pattern = <<PATTERN
{
    ($.errorCode = "*UnauthorizedOperation") || ($.errorCode ="AccessDenied*") 
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "Unauthorized_API_Calls"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "DD_BP_Alarm_Unauthorized_API_Calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Unauthorized_API_Calls"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of unauthorized AWS API calls."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
