resource "aws_s3_bucket" "cloudtrail_bucket" {
    bucket = "my-cloudtrail-bucket202505301625"
    force_destroy = true
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
    statement {
      
      sid = "AWSCloudTrailAclCheck"
      effect = "Allow"
      principals {
        
        type = "Service"
        identifiers = ["cloudtrail.amazonaws.com"]
      }
      actions = ["s3:GetBucketAcl"]
      resources = [aws_s3_bucket.cloudtrail_bucket.arn]
      condition {
        test = "StringEquals"
        variable = "aws:SourceArn"
        values = ["${aws_cloudtrail.cloudtrail.arn}"]
      }
    }
    statement {
        sid = "AWSCloudTrailWrite"
        effect = "Allow"
        principals {
            type = "Service"
            identifiers = ["cloudtrail.amazonaws.com"]
        }
        actions = ["s3:PutObject"]
        resources = ["${aws_s3_bucket.cloudtrail_bucket.arn}/*"]
        condition {
            test = "StringEquals"
            variable = "s3:x-amz-acl"
            values = ["bucket-owner-full-control"]
        }
        condition {
            test = "StringEquals"
            variable = "aws:SourceArn"
            values = ["${aws_cloudtrail.cloudtrail.arn}"]
        }    
    }
}
resource "aws_s3_bucket_policy" "aws_ct_bucket_policy" {
    bucket = aws_s3_bucket.cloudtrail_bucket.id
    policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
  
}