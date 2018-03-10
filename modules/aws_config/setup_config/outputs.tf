output "is_complete" {
  value = "${aws_config_delivery_channel.delivery_channel.name}"
}

output "sns_topic_arn" {
  value = "${aws_sns_topic.config_stream.arn}"
}
