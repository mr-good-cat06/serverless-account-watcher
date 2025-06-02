# =============================================================================
# s3.tf - S3 Bucket for CloudTrail Logs
# =============================================================================
# This file creates the S3 bucket where CloudTrail stores log files,
# along with the necessary bucket policies and security configurations.

# Get current AWS account information for policy construction
data "aws_caller_identity" "current" {}    # Current AWS account ID
data "aws_region" "current" {}             # Current AWS region

# S3 bucket for storing CloudTrail log files
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "my-cloudtrail-bucket202505301625"      # Unique bucket name with timestamp
  force_destroy = true                                    # Allow Terraform to delete non-empty bucket
}

# IAM policy document for CloudTrail S3 bucket access
# This policy allows CloudTrail service to write logs to the S3 bucket
data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  
  # Statement allowing CloudTrail to check bucket ACL
  statement {
    sid    = "AWSCloudTrailAclCheck"                      # Unique statement identifier
    effect = "Allow"
    
    # CloudTrail service principal
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    
    actions   = ["s3:GetBucketAcl"]                       # Permission to read bucket ACL
    resources = [aws_s3_bucket.cloudtrail_bucket.arn]     # This specific bucket
    
    # Condition to ensure request comes from specific CloudTrail
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      # Construct CloudTrail ARN manually to avoid circular dependency
      values = ["arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/my-cloudtrail"]
    }
  }
  
  # Statement allowing CloudTrail to write log files to bucket
  statement {
    sid    = "AWSCloudTrailWrite"                         # Unique statement identifier
    effect = "Allow"
    
    # CloudTrail service principal
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    
    actions   = ["s3:PutObject"]                          # Permission to write objects
    resources = ["${aws_s3_bucket.cloudtrail_bucket.arn}/*"]  # All objects in bucket
    
    # Ensure CloudTrail sets proper ACL on log files
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]            # Required ACL for CloudTrail
    }
    
    # Condition to ensure request comes from specific CloudTrail
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      # Same constructed ARN as above
      values = ["arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/my-cloudtrail"]
    }
  }
}

# Apply the IAM policy to the S3 bucket
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id             # Target bucket
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json  # Policy JSON
}

# Block all public access to the CloudTrail S3 bucket
# This is a security best practice to prevent accidental public exposure
resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_pab" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true                          # Block public ACLs
  block_public_policy     = true                          # Block public bucket policies
  ignore_public_acls      = true                          # Ignore existing public ACLs
  restrict_public_buckets = true                          # Restrict public bucket access
}
