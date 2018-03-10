resource "aws_kms_key" "k" {
  description         = "DD_KMS_Key"
  enable_key_rotation = "true"
}
