# Implements AWS CIS Foundations Benchmark 3.3
resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  name = "DD_BP_MetricFilter_Root_Account_Usage"

  pattern = <<PATTERN
{
    ($.userIdentity.type = "Root") && ($.userIdentity.invokedBy NOT EXISTS) && ($.eventType != "AwsServiceEvent")
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "Root_Account_Usage"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_account_usage" {
  alarm_name          = "DD_BP_Alarm_Root_Account_Usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Root_Account_Usage"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number times the root account is used."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
