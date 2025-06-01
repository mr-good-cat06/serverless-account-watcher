# CloudTrail configuration with EventBridge integration
resource "aws_cloudtrail" "cloudtrail" {
  name           = "my-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.id
  
  # Make sure the bucket policy is applied before creating CloudTrail
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
  
  # CRITICAL: Enable CloudWatch Events/EventBridge integration
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_log_file_validation   = true
  
  # Add event selectors to capture the events you want to monitor
}