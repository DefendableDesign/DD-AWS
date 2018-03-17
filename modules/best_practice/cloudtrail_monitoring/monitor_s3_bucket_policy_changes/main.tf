# Implements AWS CIS Foundations Benchmark 3.8
resource "aws_cloudwatch_log_metric_filter" "s3_bucket_policy_changes" {
  name = "DD_BP_MetricFilter_S3_Bucket_Policy_Changes"

  pattern = <<PATTERN
{
  ($.eventSource = s3.amazonaws.com) && 
  (
    ($.eventName = PutBucketAcl) || 
    ($.eventName = PutBucketPolicy) || 
    ($.eventName = PutBucketCors) || 
    ($.eventName = PutBucketLifecycle) || 
    ($.eventName = PutBucketReplication) || 
    ($.eventName = DeleteBucketPolicy) || 
    ($.eventName = DeleteBucketCors) || 
    ($.eventName = DeleteBucketLifecycle) || 
    ($.eventName = DeleteBucketReplication)
  ) 
}
PATTERN

  log_group_name = "${var.log_group_name}"

  metric_transformation {
    name          = "S3_Bucket_Policy_Changes"
    namespace     = "DD_BP_Metrics"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_bucket_policy_changes" {
  alarm_name          = "DD_BP_Alarm_S3_Bucket_Policy_Changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "S3_Bucket_Policy_Changes"
  namespace           = "DD_BP_Metrics"
  statistic           = "Sum"
  period              = "60"
  threshold           = "1"
  alarm_description   = "This metric counts the number of S3 bucket policy change events."
  alarm_actions       = ["${var.sns_topic_arn}"]
  treat_missing_data  = "notBreaching"
}
