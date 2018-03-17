# Implements AWS CIS Foundations Benchmark 3.12
resource "aws_cloudwatch_log_metric_filter" "network_gateway_changes" {
  name = "DD_BP_MetricFilter_Network_Gateway_Changes"

  pattern = <<PATTERN
{
  ($.eventName = CreateCustomerGateway) || 
  ($.eventName = DeleteCustomerGateway) || 
  ($.eventName = AttachInternetGateway) || 
  ($.eventName = CreateInternetGateway) || 
  ($.eventName = DeleteInternetGateway) || 
  ($.eventName = DetachInternetGateway) 
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "Network_Gateway_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "network_gateway_changes" {
  alarm_name          = "DD_BP_Alarm_Network_Gateway_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Network_Gateway_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of network gateway changes."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
