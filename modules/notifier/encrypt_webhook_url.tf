data "aws_kms_ciphertext" "slack_webhook_url" {
  count     = "${var.slack_webhook_url == "" ? 0 : 1}"
  key_id    = "${var.kms_key_id}"
  plaintext = "${var.slack_webhook_url}"
}
