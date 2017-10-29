provider "aws" {
    region  = "${var.region}"
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
}

module "s3_public_read" {
    source = "./s3_public_read"
    config_is_setup = "${module.config_setup.is_complete}"
}

module "s3_public_write" {
    source = "./s3_public_write"
    config_is_setup = "${module.config_setup.is_complete}"
}