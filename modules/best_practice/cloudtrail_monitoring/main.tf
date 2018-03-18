module "sns" {
  source = "./sns"
}

module "monitor_unauthorized_api_calls" {
  source         = "./monitor_unauthorized_api_calls"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}

module "monitor_console_sign_in_without_mfa" {
  source         = "./monitor_console_sign_in_without_mfa"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}

module "monitor_root_account_usage" {
  source         = "./monitor_root_account_usage"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}

module "monitor_iam_policy_changes" {
  source         = "./monitor_iam_policy_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}

module "monitor_cloudtrail_config_changes" {
  source         = "./monitor_cloudtrail_config_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}

module "monitor_console_sign_in_failures" {
  source         = "./monitor_console_sign_in_failures"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
  enable         = "${var.enable_cis_level_2_alerts == "true" ? 1 : 0}"
}

module "monitor_disable_delete_cmk" {
  source         = "./monitor_disable_delete_cmk"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
  enable         = "${var.enable_cis_level_2_alerts == "true" ? 1 : 0}"
}

module "monitor_s3_bucket_policy_changes" {
  source         = "./monitor_s3_bucket_policy_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}

module "monitor_aws_config_changes" {
  source         = "./monitor_aws_config_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
  enable         = "${var.enable_cis_level_2_alerts == "true" ? 1 : 0}"
}

module "monitor_security_group_changes" {
  source         = "./monitor_security_group_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
  enable         = "${var.enable_cis_level_2_alerts == "true" ? 1 : 0}"
}

module "monitor_nacl_changes" {
  source         = "./monitor_nacl_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
  enable         = "${var.enable_cis_level_2_alerts == "true" ? 1 : 0}"
}

module "monitor_network_gateway_changes" {
  source         = "./monitor_network_gateway_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}

module "monitor_route_table_changes" {
  source         = "./monitor_route_table_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}

module "monitor_vpc_changes" {
  source         = "./monitor_vpc_changes"
  log_group_name = "${var.log_group_name}"
  sns_topic_arn  = "${module.sns.sns_topic_arn}"
}
