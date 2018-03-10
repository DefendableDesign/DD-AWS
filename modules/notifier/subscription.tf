resource "aws_sns_topic_subscription" "config_notifier" {
  topic_arn = "${var.config_sns_arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.lf_notifier.arn}"
}

resource "aws_sns_topic_subscription" "alert_notifier" {
  topic_arn = "${var.monitoring_sns_arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.lf_notifier.arn}"
}
