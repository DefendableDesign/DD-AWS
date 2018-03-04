output "remediation_coordinator_lambda_arn" {
    value = "${aws_lambda_function.lf_remediation_coordinator.arn}"
}