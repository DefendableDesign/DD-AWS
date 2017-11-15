resource "aws_config_config_rule" "r" {
  name = "Check-CloudTrail-Enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  count = "${var.config_is_setup}"
}
