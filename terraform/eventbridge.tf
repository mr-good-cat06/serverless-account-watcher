# =============================================================================
# eventbridge.tf - EventBridge Rules and Targets
# =============================================================================
# This file configures EventBridge to capture CloudTrail events and route them
# to appropriate targets (Lambda function) for processing and alerting.

# EventBridge rule to capture S3 bucket events from CloudTrail
# CloudTrail automatically sends events to the default event bus
resource "aws_cloudwatch_event_rule" "notify_me" {
  name        = "notify-me"                              # Name of the EventBridge rule
  description = "Capture S3 bucket events from CloudTrail"
  
  # CloudTrail events are automatically sent to the default event bus
  # No need to specify event_bus_name for default bus
  
  # Event pattern to match specific S3 API calls via CloudTrail
  event_pattern = jsonencode({
    source      = ["aws.s3"]                             # Filter for S3 service events
    detail-type = ["AWS API Call via CloudTrail"]        # CloudTrail event type
    detail = {
      eventSource = ["s3.amazonaws.com"]                 # Ensure it's from S3 service
      eventName   = [                                    # Specific S3 API calls to monitor
        "CreateBucket",        # New bucket creation
        "DeleteBucket",        # Bucket deletion
        "PutBucketPolicy",     # Bucket policy changes
        "DeleteBucketPolicy",  # Bucket policy deletion
        "PutBucketAcl",        # Bucket ACL changes
        "DeleteBucketAcl"      # Bucket ACL deletion
      ]
    }
  })
}

# EventBridge target to send matched events to Lambda function
resource "aws_cloudwatch_event_target" "notify_me_target" {
  rule      = aws_cloudwatch_event_rule.notify_me.name   # Reference to the rule above
  target_id = "SendToLambda"                             # Unique identifier for this target
  arn       = aws_lambda_function.lambda_for_alerting.arn # Lambda function ARN to invoke
  # event_bus_name is not needed for default bus
}

# Lambda permission to allow EventBridge to invoke the function
# This is required for EventBridge to successfully call the Lambda function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"        # Unique statement identifier
  action        = "lambda:InvokeFunction"                 # Permission to invoke Lambda
  function_name = aws_lambda_function.lambda_for_alerting.function_name
  principal     = "events.amazonaws.com"                 # EventBridge service principal
  source_arn    = aws_cloudwatch_event_rule.notify_me.arn # Specific rule ARN for security
}

# Optional: CloudWatch Log Group for EventBridge rule debugging
# This helps troubleshoot EventBridge rule matching and execution
resource "aws_cloudwatch_log_group" "eventbridge_logs" {
  name              = "/aws/events/rule/notify-me"       # Standard naming for EventBridge logs
  retention_in_days = 7                                  # Short retention for debugging logs
}

# Optional: Debug target to send events to CloudWatch Logs
# This allows you to see what events are being matched by the rule
resource "aws_cloudwatch_event_target" "debug_target" {
  rule      = aws_cloudwatch_event_rule.notify_me.name   # Same rule as Lambda target
  target_id = "SendToCloudWatchLogs"                     # Unique identifier for debug target
  arn       = aws_cloudwatch_log_group.eventbridge_logs.arn # CloudWatch Logs destination
}

