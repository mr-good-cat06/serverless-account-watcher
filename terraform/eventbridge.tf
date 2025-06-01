# Use the default event bus for CloudTrail events
# CloudTrail automatically sends events to the default event bus, not custom ones
resource "aws_cloudwatch_event_rule" "notify_me" {
  name        = "notify-me"
  description = "Capture S3 bucket events from CloudTrail"
  
  # CloudTrail events go to the default event bus
  # event_bus_name is not needed for default bus
  
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["s3.amazonaws.com"]
      eventName   = [
        "CreateBucket",
        "DeleteBucket", 
        "PutBucketPolicy",
        "DeleteBucketPolicy",
        "PutBucketAcl",
        "DeleteBucketAcl"
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "notify_me_target" {
  rule      = aws_cloudwatch_event_rule.notify_me.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.lambda_for_alerting.arn
  # Remove event_bus_name for default bus
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_for_alerting.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.notify_me.arn
}

# Optional: Add CloudWatch Log Group for EventBridge rule debugging
resource "aws_cloudwatch_log_group" "eventbridge_logs" {
  name              = "/aws/events/rule/notify-me"
  retention_in_days = 7
}

# Optional: Add a test target to CloudWatch Logs for debugging
resource "aws_cloudwatch_event_target" "debug_target" {
  rule      = aws_cloudwatch_event_rule.notify_me.name
  target_id = "SendToCloudWatchLogs"
  arn       = aws_cloudwatch_log_group.eventbridge_logs.arn
}