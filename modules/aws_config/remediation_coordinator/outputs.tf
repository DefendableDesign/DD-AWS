output "remediation_coordinator_lambda_arn" {
  value = "${aws_lambda_function.lf_remediation_coordinator.arn}"
}

output "remediation_queue_url" {
  value = "${aws_sqs_queue.q.id}"
}

output "remediation_queue_arn" {
  value = "${aws_sqs_queue.q.arn}"
}
