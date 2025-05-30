resource "aws_ssm_parameter" "slack-webhook-url" {
    name = "/alerts/slack-webhook"
    type = "SecureString"
    value = "${var.slack_webhook_url}"
}


resource "aws_ssm_parameter" "sns=topic.arn" {
    name = "/alerts/sns-topic-arn"
    type = "SecureString"
    value = "${aws_sns_topic.alert-me.arn}"
}

