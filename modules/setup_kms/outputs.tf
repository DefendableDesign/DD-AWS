output "kms_arn" {
  value = "${aws_kms_key.k.arn}"
}

output "kms_key_id" {
  value = "${aws_kms_key.k.key_id}"
}
