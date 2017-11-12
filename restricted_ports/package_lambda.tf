data "archive_file" "lambda_package" {
    type = "zip"
    source_dir = "${path.module}/lambda_function"
    output_path = "${var.temp_dir}/DD-AWSConfig-EC2ExposedPorts.zip"
}
