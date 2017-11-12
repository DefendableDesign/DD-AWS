resource "aws_config_delivery_channel" "delivery_channel" {
  name           = "1"
  s3_bucket_name = "${aws_s3_bucket.b.bucket}"
  depends_on     = ["aws_config_configuration_recorder.recorder"]
}

data "aws_caller_identity" "current" {}


resource "aws_s3_bucket" "b" {
  bucket        = "${data.aws_caller_identity.current.account_id}-config"
  force_destroy = true
}

resource "aws_iam_role_policy" "p" {
  name = "AWSConfig-S3-Policy"
  role = "${aws_iam_role.r.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
       "Effect": "Allow",
       "Action": ["s3:PutObject*"],
       "Resource": ["${aws_s3_bucket.b.arn}/*"],
       "Condition":
        {
          "StringLike":
            {
              "s3:x-amz-acl": "bucket-owner-full-control"
            }
        }
     },
     {
       "Effect": "Allow",
       "Action": ["s3:GetBucketAcl"],
       "Resource": "${aws_s3_bucket.b.arn}"
     }
  ]
}
POLICY
}