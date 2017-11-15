resource "aws_iam_role" "r_remediation" {
    name = "DD-AWSConfig-EC2ExposedPorts-Remediation-Role"

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
    name = "DD-AWSConfig-EC2ExposedPorts-Policy"
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
            "Resource": "${aws_sqs_queue.q.arn}"
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

resource "aws_lambda_function" "lf_remediation" {
    filename         = "${data.archive_file.lambda_remediation.output_path}"
    function_name    = "DD_AWSConfig_EC2ExposedPorts_Remediation"
    role             = "${aws_iam_role.r_remediation.arn}"
    handler          = "DD-AWSConfig-EC2ExposedPorts-Remediation.lambda_handler"
    source_code_hash = "${base64sha256(file("${data.archive_file.lambda_remediation.output_path}"))}"
    runtime          = "python2.7"
    timeout          = "10"
}

resource "aws_lambda_permission" "with_events" {
    statement_id  = "DD-AWSConfig-EC2ExposedPorts-Remediation-LambdaPermission"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lf_remediation.function_name}"
    principal     = "events.amazonaws.com"
}

resource "aws_cloudwatch_event_rule" "trigger_remediation" {
  name        = "DD_AWSConfig_EC2ExposedPorts_Remediation_Trigger"
  description = "Periodically triggers the EC2ExposedPorts remediation process."
  schedule_expression = "rate(5 minutes)"
}

#Need to change this to watch CloudTrail for Config PutEvaluations as trigger
resource "aws_cloudwatch_event_target" "lf" {
  rule      = "${aws_cloudwatch_event_rule.trigger_remediation.name}"
  target_id = "DD-AWSConfig-EC2ExposedPorts-Remediation"
  arn       = "${aws_lambda_function.lf_remediation.arn}"
  input     = "{\"sqsUrl\": \"https://sqs.ap-southeast-2.amazonaws.com/176384081491/DD_AWSConfig_EC2ExposedPorts_RemediationQueue\" }"
}
