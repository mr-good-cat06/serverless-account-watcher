# CloudTrail configuration
resource "aws_cloudtrail" "cloudtrail" {
  name           = "my-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.id
  
  # Make sure the bucket policy is applied before creating CloudTrail
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
  
  # Optional: Enable log file validation
  enable_log_file_validation = true
  
  # Optional: Include global service events
  include_global_service_events = true
  
  # Optional: Multi-region trail
  is_multi_region_trail = true
}