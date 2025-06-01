# cloudwatch.tf - Add monitoring and alarms
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/my-cloudtrail"
  retention_in_days = 30
}

# CloudWatch alarm for Lambda errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "lambda-alerting-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = [aws_sns_topic.alert-me.arn]

  dimensions = {
    FunctionName = aws_lambda_function.lambda_for_alerting.function_name
  }
}

# CloudWatch alarm for EventBridge rule failures
resource "aws_cloudwatch_metric_alarm" "eventbridge_failures" {
  alarm_name          = "eventbridge-rule-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors EventBridge rule failures"
  alarm_actions       = [aws_sns_topic.alert-me.arn]

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.notify_me.name
  }
}