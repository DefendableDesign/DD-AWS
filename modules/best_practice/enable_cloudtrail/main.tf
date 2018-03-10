data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "trail" {
  name                          = "DD_BP_CloudTrail_Trail"
  s3_bucket_name                = "${aws_s3_bucket.b.id}"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.lg.arn}"
  cloud_watch_logs_role_arn     = "${aws_iam_role.r_cloudwatch.arn}"

  #  event_selector {
  #    read_write_type           = "All"
  #    include_management_events = true
  #  }
}
