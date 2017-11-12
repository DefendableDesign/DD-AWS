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

resource "aws_lambda_permission" "with_sns" {
    statement_id  = "DD-AWSConfig-EC2ExposedPorts-LambdaPermission"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.lf.function_name}"
    principal     = "config.amazonaws.com"
}

resource "aws_lambda_function" "lf" {
    filename         = "${data.archive_file.lambda_package.output_path}"
    function_name    = "DD_AWSConfig_EC2ExposedPorts"
    role             = "${aws_iam_role.r.arn}"
    handler          = "DD-AWSConfig-EC2ExposedPorts.lambda_handler"
    source_code_hash = "${base64sha256(file("${data.archive_file.lambda_package.output_path}"))}"
    runtime          = "python2.7"
}