provider "aws" {
    region  = "${var.region}"
}

terraform {
    backend "s3" {
        encrypt = true
        key = "DD_Terraform/terraform.tfstate"
    }
}

module "config_setup" {
    source = "./config_setup"
}

module "enable_cloudtrail" {
    source = "./enable_cloudtrail"
    config_is_setup = "${module.config_setup.is_complete}"
}

module "iam_password_policy" {
    source = "./iam_password_policy"
    config_is_setup = "${module.config_setup.is_complete}"
}

module "restricted_ports" {
    source = "./restricted_ports"
    config_is_setup = "${module.config_setup.is_complete}"
    remediation_queue_url = "${module.config_setup.remediation_queue_url}"
    remediation_queue_arn = "${module.config_setup.remediation_queue_arn}"
    prohibited_ports = "22,1433,3306,3389"
}

module "restricted_ports_remediation" {
    source = "./restricted_ports_remediation"
    config_is_setup = "${module.config_setup.is_complete}"
    remediation_queue_url = "${module.config_setup.remediation_queue_url}"
    remediation_queue_arn = "${module.config_setup.remediation_queue_arn}"
    remediation_coordinator_lambda_arn = "${module.remediation_setup.remediation_coordinator_lambda_arn}"
}

module "s3_public_access" {
    source = "./s3_public_access"
    config_is_setup = "${module.config_setup.is_complete}"
    remediation_queue_url = "${module.config_setup.remediation_queue_url}"
    remediation_queue_arn = "${module.config_setup.remediation_queue_arn}"
}

module "s3_public_access_remediation" {
    source = "./s3_public_access_remediation"
    config_is_setup = "${module.config_setup.is_complete}"
    remediation_queue_url = "${module.config_setup.remediation_queue_url}"
    remediation_queue_arn = "${module.config_setup.remediation_queue_arn}"
    remediation_coordinator_lambda_arn = "${module.remediation_setup.remediation_coordinator_lambda_arn}"
}

module "remediation_setup" {
    source = "./remediation_setup"
    config_is_setup = "${module.config_setup.is_complete}"
    remediation_queue_url = "${module.config_setup.remediation_queue_url}"
    remediation_queue_arn = "${module.config_setup.remediation_queue_arn}"
    enable_auto_response = "${var.enable_auto_response}"
    region = "${var.region}"
}