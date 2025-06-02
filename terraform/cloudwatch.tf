# =============================================================================
# cloudwatch.tf - CloudWatch Monitoring and Alarms
# =============================================================================
# This file sets up CloudWatch log groups and alarms to monitor the health
# and performance of your alerting infrastructure.

# CloudWatch log group for CloudTrail logs
# This provides a centralized location for CloudTrail log storage with automatic retention
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/my-cloudtrail"    # Standard naming convention for CloudTrail logs
  retention_in_days = 30                                # Retain logs for 30 days to control costs
}

# CloudWatch alarm for Lambda function errors
# This alarm triggers when the Lambda function encounters errors processing events
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-alerting-errors"         # Descriptive name for the alarm
  comparison_operator = "GreaterThanThreshold"           # Trigger when errors exceed threshold
  evaluation_periods  = "2"                             # Wait for 2 consecutive periods before alarming
  metric_name         = "Errors"                         # AWS Lambda error metric
  namespace           = "AWS/Lambda"                     # AWS Lambda namespace
  period              = "60"                             # Check every 60 seconds
  statistic           = "Sum"                            # Sum all errors in the period
  threshold           = "0"                              # Alert on any errors (threshold of 0)
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = [aws_sns_topic.alert-me.arn]    # Send notifications to SNS topic

  # Filter to specific Lambda function
  dimensions = {
    FunctionName = aws_lambda_function.lambda_for_alerting.function_name
  }
}

# CloudWatch alarm for EventBridge rule failures
# This alarm monitors for failures in EventBridge rule processing
resource "aws_cloudwatch_metric_alarm" "eventbridge_failures" {
  alarm_name          = "eventbridge-rule-failures"      # Descriptive name for the alarm
  comparison_operator = "GreaterThanThreshold"           # Trigger when failures exceed threshold
  evaluation_periods  = "1"                             # Alert immediately on first failure
  metric_name         = "FailedInvocations"             # EventBridge failure metric
  namespace           = "AWS/Events"                     # AWS EventBridge namespace
  period              = "300"                            # Check every 5 minutes
  statistic           = "Sum"                            # Sum all failures in the period
  threshold           = "0"                              # Alert on any failures
  alarm_description   = "This metric monitors EventBridge rule failures"
  alarm_actions       = [aws_sns_topic.alert-me.arn]    # Send notifications to SNS topic

  # Filter to specific EventBridge rule
  dimensions = {
    RuleName = aws_cloudwatch_event_rule.notify_me.name
  }
}
