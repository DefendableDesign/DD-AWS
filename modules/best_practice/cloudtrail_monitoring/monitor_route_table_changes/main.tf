# Implements AWS CIS Foundations Benchmark 3.13
resource "aws_cloudwatch_log_metric_filter" "route_table_changes" {
  name = "DD_BP_MetricFilter_Route_Table_Changes"

  pattern = <<PATTERN
{
  ($.eventName = CreateRoute) || 
  ($.eventName = CreateRouteTable) || 
  ($.eventName = ReplaceRoute) || 
  ($.eventName = ReplaceRouteTableAssociation) || 
  ($.eventName = DeleteRouteTable) || 
  ($.eventName = DeleteRoute) || 
  ($.eventName = DisassociateRouteTable)
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "Route_Table_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "route_table_changes" {
  alarm_name          = "DD_BP_Alarm_Route_Table_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "Route_Table_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of unauthorized AWS API calls"
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
