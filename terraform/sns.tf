# =============================================================================
# sns.tf - SNS Topic for Alert Notifications
# =============================================================================
# This file creates the SNS topic and subscription for sending email alerts
# when security events are detected.

# SNS topic for sending alerts
resource "aws_sns_topic" "alert-me" {
    name= "alertmequick"                                  # SNS topic name
}

# Email subscription to the SNS topic
# This sends email notifications to the specified address
resource "aws_sns_topic_subscription" "alert-me-email" {
    topic_arn = aws_sns_topic.alert-me.arn                # SNS topic ARN
    protocol = "email"                                    # Email protocol
    endpoint = "${var.email}"                             # Email address from variable
}

# Output the SNS topic ARN for reference by other resources
output "sns_topic_arn" {
  value = aws_sns_topic.alert-me.arn
}
