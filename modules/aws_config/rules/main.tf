module "enable_cloudtrail" {
  source          = "./enable_cloudtrail"
  config_is_setup = "${var.config_is_setup}"
}

module "iam_password_policy" {
  source          = "./iam_password_policy"
  config_is_setup = "${var.config_is_setup}"
}

module "restricted_ports" {
  source                = "./restricted_ports"
  config_is_setup       = "${var.config_is_setup}"
  remediation_queue_url = "${var.remediation_queue_url}"
  remediation_queue_arn = "${var.remediation_queue_arn}"
  prohibited_ports      = "22,1433,3306,3389"
}

module "restricted_ports_remediation" {
  source                             = "./restricted_ports_remediation"
  remediation_queue_url              = "${var.remediation_queue_url}"
  remediation_queue_arn              = "${var.remediation_queue_arn}"
  remediation_coordinator_lambda_arn = "${var.remediation_coordinator_lambda_arn}"
  notifier_enabled                   = "${var.notifier_enabled}"
}

module "s3_public_access" {
  source                = "./s3_public_access"
  config_is_setup       = "${var.config_is_setup}"
  remediation_queue_url = "${var.remediation_queue_url}"
  remediation_queue_arn = "${var.remediation_queue_arn}"
}

module "s3_public_access_remediation" {
  source                             = "./s3_public_access_remediation"
  remediation_queue_url              = "${var.remediation_queue_url}"
  remediation_queue_arn              = "${var.remediation_queue_arn}"
  remediation_coordinator_lambda_arn = "${var.remediation_coordinator_lambda_arn}"
  notifier_enabled                   = "${var.notifier_enabled}"
}
