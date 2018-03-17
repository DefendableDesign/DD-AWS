# Implements AWS CIS Foundations Benchmark 3.9
resource "aws_cloudwatch_log_metric_filter" "aws_config_changes" {
  name  = "DD_BP_MetricFilter_AWS_Config_Changes"
  count = "${var.enable}"

  pattern = <<PATTERN
{
  ($.eventSource = config.amazonaws.com) && (
    ($.eventName=StopConfigurationRecorder) || 
    ($.eventName=DeleteDeliveryChannel) || 
    ($.eventName=PutDeliveryChannel) || 
    ($.eventName=PutConfigurationRecorder)
  )
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "AWS_Config_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "aws_config_changes" {
  count               = "${var.enable}"
  alarm_name          = "DD_BP_Alarm_AWS_Config_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "AWS_Config_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of changes to AWS Config configuration."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
