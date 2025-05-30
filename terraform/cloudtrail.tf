resource "aws_cloudtrail" "cloudtrail" {
    name = "my-cloudtrail"
    s3_bucket_name = aws_s3_bucket.cloudtrail_bucket.id
}

