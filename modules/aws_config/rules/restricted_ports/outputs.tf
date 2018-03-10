output "remediation_lambda_arn" {
    value = "${aws_lambda_function.lf_configrule.arn}"
}