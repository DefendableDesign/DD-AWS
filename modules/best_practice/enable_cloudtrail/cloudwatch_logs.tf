resource "aws_cloudwatch_log_group" "lg" {
  name              = "DD_BP_CloudWatch_CloudTrail_LogGroup"
  retention_in_days = 3
}

resource "aws_iam_role" "r_cloudwatch" {
  name = "DD_BP_Role_CloudTrail_CloudWatch"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "p_remediation" {
  name = "DD_BP_Policy_CloudTrail_CloudWatch"
  role = "${aws_iam_role.r_cloudwatch.id}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "${aws_cloudwatch_log_group.lg.arn}"
        }
    ]
}
POLICY
}
