resource "aws_config_config_rule" "r" {
  name = "DD_Config_CloudTrail_Enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  count = "${var.config_is_setup}"
}
