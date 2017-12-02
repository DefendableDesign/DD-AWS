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
    "MinimumPasswordLength":"10",
    "PasswordReusePrevention":"12",
    "MaxPasswordAge":"30"
}
JSON

  count = "${var.config_is_setup}"
}
