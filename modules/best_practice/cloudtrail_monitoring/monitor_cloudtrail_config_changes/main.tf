# Implements AWS CIS Foundations Benchmark 3.5
resource "aws_cloudwatch_log_metric_filter" "cloudtrail_config_changes" {
  name = "DD_BP_MetricFilter_CloudTrail_Config_Changes"

  pattern = <<PATTERN
{
  ($.eventName = CreateTrail) || 
  ($.eventName = UpdateTrail) || 
  ($.eventName = DeleteTrail) || 
  ($.eventName = StartLogging) || 
  ($.eventName = StopLogging)
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "CloudTrail_Config_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudtrail_config_changes" {
  alarm_name          = "DD_BP_Alarm_CloudTrail_Config_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CloudTrail_Config_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of changes to CloudTrail configuration."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
