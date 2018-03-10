resource "aws_iam_role" "r_remediation_coordinator" {
  name = "DD_Config_Role_Remediation"

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

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "p_remediation_coordinator" {
  name = "DD_Config_Policy_Remediation"
  role = "${aws_iam_role.r_remediation_coordinator.id}"

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
            "Resource": "${aws_sqs_queue.q.arn}"
        },
        {
            "Action": [
                "lambda:InvokeFunction",
                "lambda:Get*"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:DD_Config_Lambda_*_Remediation"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
POLICY
}

resource "aws_lambda_function" "lf_remediation_coordinator" {
  filename         = "${data.archive_file.lambda_remediation_coordinator.output_path}"
  function_name    = "DD_Config_Lambda_Remediation_Coordinator"
  role             = "${aws_iam_role.r_remediation_coordinator.arn}"
  handler          = "dd_config_lambda_remediation_coordinator.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.lambda_remediation_coordinator.output_path}"))}"
  runtime          = "python2.7"
  timeout          = "60"
}

resource "aws_lambda_permission" "p" {
  statement_id  = "DD_Config_LambdaPermission_Remediation_Coordinator"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lf_remediation_coordinator.function_name}"
  principal     = "events.amazonaws.com"
}
