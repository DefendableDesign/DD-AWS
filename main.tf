provider "aws" {
  region  = "${var.region}"
  version = "1.11"
}

terraform {
  backend "s3" {
    encrypt = true
    key     = "DD_Terraform/terraform.tfstate"
  }
}

module "kms" {
  source = "./modules/setup_kms"
}

module "best_practice" {
  source     = "./modules/best_practice"
  kms_key_id = "${module.kms.kms_key_id}"
}

module "config" {
  source     = "./modules/aws_config/setup_config"
  kms_key_id = "${module.kms.kms_key_id}"
}

module "remediation" {
  source               = "./modules/aws_config/remediation_coordinator"
  enable_auto_response = "${var.enable_auto_response}"
  region               = "${var.region}"
}

module "rules" {
  source                             = "./modules/aws_config/rules"
  config_is_setup                    = "${module.config.is_complete}"
  remediation_queue_url              = "${module.remediation.remediation_queue_url}"
  remediation_queue_arn              = "${module.remediation.remediation_queue_arn}"
  remediation_coordinator_lambda_arn = "${module.remediation.remediation_coordinator_lambda_arn}"
}
