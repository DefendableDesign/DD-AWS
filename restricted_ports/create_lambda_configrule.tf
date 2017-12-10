resource "aws_iam_role" "r_configrule" {
    name = "DD_Config_Role_EC2_OpenPorts"

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

resource "aws_iam_role_policy" "p_configrule" {
    name = "DD_Config_Policy_EC2_OpenPorts"
    role = "${aws_iam_role.r_configrule.id}"
    
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
        }
    ]
}
POLICY
}

resource "aws_lambda_function" "lf_configrule" {
    filename         = "${data.archive_file.lambda_configrule.output_path}"
    function_name    = "DD_Config_Lambda_EC2_OpenPorts"
    role             = "${aws_iam_role.r_configrule.arn}"
    handler          = "dd_config_lambda_ec2_openports.lambda_handler"
    source_code_hash = "${base64sha256(file("${data.archive_file.lambda_configrule.output_path}"))}"
    runtime          = "python2.7"
    timeout          = "10"
}

resource "aws_lambda_permission" "with_config" {
    statement_id  = "DD_Config_LambdaPermission_EC2_OpenPorts"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lf_configrule.function_name}"
    principal     = "config.amazonaws.com"
}
