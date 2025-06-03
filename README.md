# AWS Security Alerting Infrastructure

A Terraform-based solution for real-time monitoring and alerting of AWS S3 bucket security events using CloudTrail, EventBridge, Lambda, and SNS.

## Architecture
![event-driven-architecture](https://github.com/user-attachments/assets/124516a6-de50-48f3-8980-91a4247ac587)

## Overview

This infrastructure automatically detects and alerts on critical S3 bucket security events such as:
- Bucket creation/deletion
- Bucket policy changes
- Bucket ACL modifications

When these events occur, the system sends immediate notifications via email and Slack to help maintain security posture.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Python 3.9+ (for Lambda function development)
- Valid Slack webhook URL (optional)
- Email address for notifications

## Required AWS Permissions

The deploying user/role needs permissions for:
- CloudTrail management
- EventBridge rules and targets
- Lambda functions
- IAM roles and policies
- S3 buckets and policies
- SNS topics and subscriptions
- SSM parameters
- CloudWatch logs and alarms

  ## Quick Start

1. **Clone and prepare**:
   ```bash
   git clone <repository>
   cd aws-security-alerting
   ```

2. **Configure variables**:

3. **Deploy infrastructure**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Confirm email subscription**:
   - Check your email for SNS subscription confirmation
   - Click the confirmation link
