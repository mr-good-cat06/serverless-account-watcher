resource "aws_sns_topic" "alert-me" {
    name= "alertmequick"
}

resource "aws_sns_topic_subscription" "alert-me-email" {
    topic_arn = aws_sns_topic.alert-me.arn
    protocol = "email"
    endpoint = "${var.email}"
}

output "sns_topic_arn" {
  value = aws_sns_topic.alert-me.arn
}

