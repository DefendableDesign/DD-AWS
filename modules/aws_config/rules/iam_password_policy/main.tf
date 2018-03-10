resource "aws_config_config_rule" "r" {
  name = "DD_Config_IAM_PasswordPolicy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = <<JSON
{
    "RequireUppercaseCharacters":"true",
    "RequireLowercaseCharacters":"true",
    "RequireSymbols":"true",
    "RequireNumbers":"true",
    "MinimumPasswordLength":"14",
    "PasswordReusePrevention":"24",
    "MaxPasswordAge":"90"
}
JSON

  count = "${var.config_is_setup}"
}
