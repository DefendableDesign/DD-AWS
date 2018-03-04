output "is_complete" {
    value = "${aws_config_delivery_channel.delivery_channel.name}"
}

output "remediation_queue_url" {
    value = "${aws_sqs_queue.q.id}"
}

output "remediation_queue_arn" {
    value = "${aws_sqs_queue.q.arn}"
}