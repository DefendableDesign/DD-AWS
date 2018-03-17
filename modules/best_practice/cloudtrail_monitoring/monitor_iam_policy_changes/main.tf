# Implements AWS CIS Foundations Benchmark 3.4
resource "aws_cloudwatch_log_metric_filter" "iam_policy_changes" {
  name = "DD_BP_MetricFilter_IAM_Policy_Changes"

  pattern = <<PATTERN
{
  ($.eventName=DeleteGroupPolicy) || 
  ($.eventName=DeleteRolePolicy) || 
  ($.eventName=DeleteUserPolicy) || 
  ($.eventName=PutGroupPolicy) || 
  ($.eventName=PutRolePolicy) || 
  ($.eventName=PutUserPolicy) || 
  ($.eventName=CreatePolicy) || 
  ($.eventName=DeletePolicy) || 
  ($.eventName=CreatePolicyVersion) || 
  ($.eventName=DeletePolicyVersion) || 
  ($.eventName=AttachRolePolicy) || 
  ($.eventName=DetachRolePolicy) || 
  ($.eventName=AttachUserPolicy) || 
  ($.eventName=DetachUserPolicy) || 
  ($.eventName=AttachGroupPolicy) || 
  ($.eventName=DetachGroupPolicy)
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "IAM_Policy_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_policy_changes" {
  alarm_name          = "DD_BP_Alarm_IAM_Policy_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "IAM_Policy_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number IAM policy changes."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
