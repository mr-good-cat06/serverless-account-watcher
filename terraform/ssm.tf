# =============================================================================
# ssm.tf - Systems Manager Parameter Store
# =============================================================================
# This file stores configuration values in AWS Systems Manager Parameter Store
# for secure access by the Lambda function.

# Store Slack webhook URL securely in SSM Parameter Store
resource "aws_ssm_parameter" "slack-webhook-url" {
    name = "/alerts/slack-webhook"                        # Parameter name with namespace
    type = "SecureString"                                 # Encrypted parameter type
    value = "${var.slack_webhook_url}"                    # Slack webhook URL from variable
}

# Store SNS topic ARN in SSM Parameter Store for Lambda access
resource "aws_ssm_parameter" "sns_topic_arn" {
    name = "/alerts/sns-topic-arn"                        # Parameter name with namespace
    type = "SecureString"                                 # Encrypted parameter type
    value = "${aws_sns_topic.alert-me.arn}"              # SNS topic ARN
}