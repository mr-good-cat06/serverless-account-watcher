##A Terraform-based solution for real-time monitoring and alerting of AWS S3 bucket security events using CloudTrail, EventBridge, Lambda, and SNS.

#Overview
This infrastructure automatically detects and alerts on critical S3 bucket security events such as:

Bucket creation/deletion
Bucket policy changes
Bucket ACL modifications

When these events occur, the system sends immediate notifications via email and Slack to help maintain security posture.
