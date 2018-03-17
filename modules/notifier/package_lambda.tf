data "archive_file" "lambda_notifier" {
  count       = "${var.slack_webhook_url == "" ? 0 : 1}"
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${var.temp_dir}/DD_Notifier_Lambda.zip"
}
