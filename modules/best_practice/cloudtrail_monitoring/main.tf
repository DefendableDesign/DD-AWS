module "sns" {
  source = "./sns"
}

module "monitor_unauthorized_api_calls" {
  source         = "./monitor_unauthorized_api_calls"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn = "${module.sns.sns_topic_arn}"
}
