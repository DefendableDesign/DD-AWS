resource "aws_iam_role" "r" {
    name = "DD-AWSConfig-EC2ExposedPorts-Role"

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


resource "aws_iam_role_policy" "p" {
    name = "DD-AWSConfig-EC2ExposedPorts-Policy"
    role = "${aws_iam_role.r.id}"
    
    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sqs:SendMessage"
            ],
            "Effect": "Allow",
            "Resource": "${aws_sqs_queue.q.arn}"
        },
        {
            "Action": [
                "config:PutEvaluations"
            ],
            "Effect": "Allow",
            "Resource": "*"
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
                "ec2:RevokeSecurityGroupIngress"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
POLICY
}

resource "aws_lambda_function" "lf_config" {
    filename         = "${data.archive_file.lambda_config.output_path}"
    function_name    = "DD_AWSConfig_EC2ExposedPorts_ConfigRule"
    role             = "${aws_iam_role.r.arn}"
    handler          = "DD-AWSConfig-EC2ExposedPorts.lambda_handler"
    source_code_hash = "${base64sha256(file("${data.archive_file.lambda_config.output_path}"))}"
    runtime          = "python2.7"
}

resource "aws_lambda_permission" "with_config" {
    statement_id  = "DD-AWSConfig-EC2ExposedPorts-LambdaPermission"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lf_config.function_name}"
    principal     = "config.amazonaws.com"
}

resource "aws_lambda_function" "lf_remediation" {
    filename         = "${data.archive_file.lambda_remediation.output_path}"
    function_name    = "DD_AWSConfig_EC2ExposedPorts_Remediation"
    role             = "${aws_iam_role.r.arn}"
    handler          = "DD-AWSConfig-EC2ExposedPorts-Remediation.lambda_handler"
    source_code_hash = "${base64sha256(file("${data.archive_file.lambda_remediation.output_path}"))}"
    runtime          = "python2.7"
}

resource "aws_lambda_permission" "with_events" {
    statement_id  = "DD-AWSConfig-EC2ExposedPorts-Remediation-LambdaPermission"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lf_remediation.function_name}"
    principal     = "events.amazonaws.com"
}