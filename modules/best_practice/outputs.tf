output "sns_topic_arn" {
  value = "${module.cloudtrail_monitoring.sns_topic_arn}"
}