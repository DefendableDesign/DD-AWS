resource "aws_config_config_rule" "r" {
  name = "Check-S3-PublicWrite"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }

  count = "${var.config_is_setup}"
}

