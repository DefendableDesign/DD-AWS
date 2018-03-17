# Implements AWS CIS Foundations Benchmark 3.11
resource "aws_cloudwatch_log_metric_filter" "nacl_changes" {
  name  = "DD_BP_MetricFilter_NACL_Changes"
  count = "${var.enable}"

  pattern = <<PATTERN
{
  ($.eventName = CreateNetworkAcl) || 
  ($.eventName = CreateNetworkAclEntry) || 
  ($.eventName = DeleteNetworkAcl) || 
  ($.eventName = DeleteNetworkAclEntry) || 
  ($.eventName = ReplaceNetworkAclEntry) || 
  ($.eventName = ReplaceNetworkAclAssociation) 
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "NACL_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "nacl_changes" {
  count               = "${var.enable}"
  alarm_name          = "DD_BP_Alarm_NACL_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "NACL_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of VPC Network ACL changes."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
