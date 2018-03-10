data "archive_file" "lambda_configrule" {
    type = "zip"
    source_dir = "${path.module}/lambda_configrule"
    output_path = "${var.temp_dir}/DD_Config_Lambda_EC2_OpenPorts.zip"
}
