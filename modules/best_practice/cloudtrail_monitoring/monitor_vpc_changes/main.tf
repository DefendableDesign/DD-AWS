# Implements AWS CIS Foundations Benchmark 3.
resource "aws_cloudwatch_log_metric_filter" "vpc_changes" {
  name = "DD_BP_MetricFilter_VPC_Changes"

  pattern = <<PATTERN
{
  ($.eventName = CreateVpc) || 
  ($.eventName = DeleteVpc) || 
  ($.eventName = ModifyVpcAttribute) || 
  ($.eventName = AcceptVpcPeeringConnection) || 
  ($.eventName = CreateVpcPeeringConnection) || 
  ($.eventName = DeleteVpcPeeringConnection) || 
  ($.eventName = RejectVpcPeeringConnection) || 
  ($.eventName = AttachClassicLinkVpc) || 
  ($.eventName = DetachClassicLinkVpc) || 
  ($.eventName = DisableVpcClassicLink) || 
  ($.eventName = EnableVpcClassicLink) 
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "VPC_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "vpc_changes" {
  alarm_name          = "DD_BP_Alarm_VPC_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "VPC_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of unauthorized AWS API calls"
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
