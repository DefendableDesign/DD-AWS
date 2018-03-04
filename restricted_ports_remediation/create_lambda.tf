resource "aws_iam_role" "r_remediation" {
    name = "DD_Config_Role_EC2_OpenPorts_Remediation"

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
    name = "DD_Config_Policy_EC2_OpenPorts_Remediation"
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
    function_name    = "DD_Config_Lambda_EC2_OpenPorts_Remediation"
    role             = "${aws_iam_role.r_remediation.arn}"
    handler          = "dd_config_lambda_ec2_openports_remediation.lambda_handler"
    source_code_hash = "${base64sha256(file("${data.archive_file.lambda_remediation.output_path}"))}"
    runtime          = "python2.7"
    timeout          = "60"
}

resource "aws_lambda_permission" "coordinator_invoke_permission" {
    statement_id  = "DD_Config_LambdaPermission_EC2_OpenPorts_Remediation"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lf_remediation.function_name}"
    principal     = "lambda.amazonaws.com"
    source_arn    = "${var.remediation_coordinator_lambda_arn}"
}
