# =============================================================================
# cloudtrail.tf - AWS CloudTrail Configuration
# =============================================================================
# This file configures AWS CloudTrail to monitor API calls and events across
# your AWS account. CloudTrail automatically integrates with EventBridge to
# enable real-time event processing and alerting.

# CloudTrail configuration with EventBridge integration
resource "aws_cloudtrail" "cloudtrail" {
  name           = "my-cloudtrail"                          # Name of the CloudTrail
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.id      # S3 bucket to store CloudTrail logs
  
  # Ensure the S3 bucket policy is applied before creating CloudTrail
  # This prevents permission errors during CloudTrail creation
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
  
  # CRITICAL: Enable CloudWatch Events/EventBridge integration
  # These settings ensure CloudTrail events are sent to EventBridge for real-time processing
  enable_logging                = true    # Enable CloudTrail logging
  include_global_service_events = true    # Include events from global services (IAM, CloudFront, etc.)
  is_multi_region_trail        = true    # Capture events from all AWS regions
  enable_log_file_validation   = true    # Enable log file integrity validation
  
  # Event selectors can be added here to capture specific events you want to monitor
  # For example, to monitor only S3 and EC2 events, you would add event_selector blocks
}
