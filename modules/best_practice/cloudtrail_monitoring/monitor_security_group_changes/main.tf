# Implements AWS CIS Foundations Benchmark 3.10
resource "aws_cloudwatch_log_metric_filter" "security_group_changes" {
  name  = "DD_BP_MetricFilter_Security_Group_Changes"
  count = "${var.enable}"

  pattern = <<PATTERN
{
  ($.eventName = AuthorizeSecurityGroupIngress) || 
  ($.eventName = AuthorizeSecurityGroupEgress) || 
  ($.eventName = RevokeSecurityGroupIngress) || 
  ($.eventName = RevokeSecurityGroupEgress) || 
  ($.eventName = CreateSecurityGroup) || 
  ($.eventName = DeleteSecurityGroup)
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "Security_Group_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "security_group_changes" {
  count               = "${var.enable}"
  alarm_name          = "DD_BP_Alarm_Security_Group_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Security_Group_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of security group changes."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
