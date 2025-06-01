# Get current AWS account ID and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 bucket for CloudTrail
resource "aws_s3_bucket" "cloudtrail_bucket" {
  bucket        = "my-cloudtrail-bucket202505301625"
  force_destroy = true
}

# S3 bucket policy - using constructed ARN instead of referencing CloudTrail resource
data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_bucket.arn]
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      # Construct the CloudTrail ARN manually to avoid circular dependency
      values = ["arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/my-cloudtrail"]
    }
  }
  
  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_bucket.arn}/*"]
    
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      # Same constructed ARN here
      values = ["arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/my-cloudtrail"]
    }
  }
}

# Apply the policy to the bucket
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

# Block public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket_pab" {
  bucket = aws_s3_bucket.cloudtrail_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

