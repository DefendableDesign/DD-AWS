output "ec2_remediation_lambda_arn" {
    value = "${aws_lambda_function.lf_remediation.arn}"
}