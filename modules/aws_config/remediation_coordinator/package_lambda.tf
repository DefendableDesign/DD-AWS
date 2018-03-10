data "archive_file" "lambda_remediation_coordinator" {
    type = "zip"
    source_dir = "${path.module}/lambda_remediation_coordinator"
    output_path = "${var.temp_dir}/DD_Config_Lambda_Remediation_Coordinator.zip"
}
