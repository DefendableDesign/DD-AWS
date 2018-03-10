resource "aws_config_delivery_channel" "delivery_channel" {
  name           = "1"
  s3_bucket_name = "${aws_s3_bucket.b.bucket}"
  sns_topic_arn  = "${aws_sns_topic.config_stream.arn}"
  depends_on     = ["aws_config_configuration_recorder.recorder"]
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "b" {
  bucket        = "dd-config-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "${var.kms_key_id}"
      }
    }
  }
}

resource "aws_iam_role_policy" "p" {
  name = "DD_Config_Policy_S3"
  role = "${aws_iam_role.r.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject*"
      ],
      "Resource": [
        "${aws_s3_bucket.b.arn}/*"
      ],
      "Condition": {
        "StringLike": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketAcl"
      ],
      "Resource": "${aws_s3_bucket.b.arn}"
    },
    {
      "Effect": "Allow",
      "Action": "sns:Publish",
      "Resource": "${aws_sns_topic.config_stream.arn}"
    }
  ]
}
POLICY
}
