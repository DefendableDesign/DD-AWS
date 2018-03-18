resource "aws_iam_role" "r_notifier" {
  count = "${var.slack_webhook_url == "" ? 0 : 1}"
  name  = "DD_Notifier_Role"

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

resource "aws_iam_role_policy" "p_notifier" {
  count = "${var.slack_webhook_url == "" ? 0 : 1}"
  name  = "DD_Notifier_Policy"
  role  = "${aws_iam_role.r_notifier.id}"

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
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "kms:Decrypt"
            ],
            "Resource": "${var.kms_arn}"
        }
    ]
}
POLICY
}

resource "aws_lambda_function" "lf_notifier" {
  count            = "${var.slack_webhook_url == "" ? 0 : 1}"
  filename         = "${data.archive_file.lambda_notifier.output_path}"
  function_name    = "DD_Notifier_Lambda"
  role             = "${aws_iam_role.r_notifier.arn}"
  handler          = "dd_notifier_lambda.lambda_handler"
  source_code_hash = "${base64sha256(file("${data.archive_file.lambda_notifier.output_path}"))}"
  runtime          = "python3.6"
  timeout          = "60"

  environment {
    variables = {
      kmsEncryptedHookUrl = "${data.aws_kms_ciphertext.slack_webhook_url.ciphertext_blob}"
      slackChannel        = "${var.slack_channel}"
    }
  }
}

resource "aws_lambda_permission" "p1" {
  count         = "${var.slack_webhook_url == "" ? 0 : 1}"
  statement_id  = "DD_Notifier_LambdaPermission_SNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lf_notifier.function_name}"
  principal     = "sns.amazonaws.com"
}
