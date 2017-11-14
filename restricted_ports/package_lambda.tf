data "archive_file" "lambda_config" {
    type = "zip"
    source_dir = "${path.module}/lambda_config_rule"
    output_path = "${var.temp_dir}/DD-AWSConfig-EC2ExposedPorts.zip"
}

data "archive_file" "lambda_remediation" {
    type = "zip"
    source_dir = "${path.module}/lambda_remediation"
    output_path = "${var.temp_dir}/DD-AWSConfig-EC2ExposedPorts-Remediation.zip"
}
