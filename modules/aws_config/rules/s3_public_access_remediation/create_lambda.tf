data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "r_remediation" {
  name = "DD_Config_Role_S3_PublicAccess_Remediation"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "p_remediation" {
  name = "DD_Config_Policy_S3_PublicAccess_Remediation"
  role = "${aws_iam_role.r_remediation.id}"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sqs:ReceiveMessage",
                "sqs:DeleteMessage"
            ],
            "Effect": "Allow",
            "Resource": "${var.remediation_queue_arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:*Bucket*Acl",
                "s3:*Bucket*Policy"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Action": [
                "lambda:InvokeFunction"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:DD_Config_Lambda_Notifier"
        }
    ]
}
POLICY
}

resource "aws_lambda_function" "lf_remediation" {
  filename         = "${data.archive_file.lambda_remediation.output_path}"
  function_name    = "DD_Config_Lambda_S3_PublicAccess_Remediation"
  role             = "${aws_iam_role.r_remediation.arn}"
  handler          = "dd_config_lambda_s3_publicaccess_remediation.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.lambda_remediation.output_path}"))}"
  runtime          = "python2.7"
  timeout          = "60"

  environment {
    variables = {
      notifierFnName  = "DD_Config_Lambda_Notifier"
      notifierEnabled = "${var.notifier_enabled}"
    }
  }
}
