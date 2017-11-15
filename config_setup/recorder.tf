#Create Recorder
resource "aws_config_configuration_recorder" "recorder" {
  name     = "AWSConfigRecorder"
  role_arn = "${aws_iam_role.r.arn}"
  recording_group = {
      all_supported = "true"
      include_global_resource_types = "true"
  }
}

resource "aws_iam_role" "r" {
  name = "AWSConfig"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "a" {
  role       = "${aws_iam_role.r.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

output "is_complete" {
    value = "${aws_config_delivery_channel.delivery_channel.name}"
}
