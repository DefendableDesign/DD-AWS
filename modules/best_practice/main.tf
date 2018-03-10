module "enable_cloudtrail" {
  source     = "./enable_cloudtrail"
  kms_key_id = "${var.kms_key_id}"
}

module "iam_password_policy" {
  source = "./iam_password_policy"
}

module "cloudtrail_monitoring" {
  source         = "./cloudtrail_monitoring"
  log_group_name = "${module.enable_cloudtrail.log_group_name}"
}
