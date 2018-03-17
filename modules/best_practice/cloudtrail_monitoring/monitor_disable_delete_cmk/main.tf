# Implements AWS CIS Foundations Benchmark 3.7
resource "aws_cloudwatch_log_metric_filter" "disable_delete_cmk" {
  name  = "DD_BP_MetricFilter_Disable_Delete_CMK"
  count = "${var.enable}"

  pattern = <<PATTERN
{
  ($.eventSource = kms.amazonaws.com) && (
    ($.eventName=DisableKey) || 
    ($.eventName=ScheduleKeyDeletion)
    )
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "Disable_Delete_CMK"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "disable_delete_cmk" {
  count               = "${var.enable}"
  alarm_name          = "DD_BP_Alarm_Disable_Delete_CMK"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Disable_Delete_CMK"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number events for disabling or scheduled deletion of customer-created CMKs."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
