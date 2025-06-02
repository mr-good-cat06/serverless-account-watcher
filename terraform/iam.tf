# =============================================================================
# iam.tf - IAM Roles and Policies
# =============================================================================
# This file defines IAM roles and policies that grant the Lambda function
# necessary permissions to access SSM parameters, publish to SNS, and write logs.

# IAM policy defining permissions for the Lambda function
resource "aws_iam_policy" "lambda_policy" {
    name = "allow_lambda_ssm_policy"                      # Descriptive policy name
    
    # Policy document with required permissions
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                # Permission to read SSM parameters for configuration
                Action = [
                    "ssm:GetParameter"                     # Read SSM parameter values
                ]      
                Effect = "Allow"
                Resource = "arn:aws:ssm:*:*:parameter/alerts/*"  # Restrict to /alerts/ namespace
            },
            {
                # Permission to publish messages to SNS topic
                Action = [
                    "sns:Publish"                          # Send notifications via SNS
                ]      
                Effect = "Allow"
                Resource = aws_sns_topic.alert-me.arn     # Specific SNS topic ARN
            },
            {
                # Standard CloudWatch Logs permissions for Lambda
                Action = [
                    "logs:CreateLogGroup",                 # Create log group if needed
                    "logs:CreateLogStream",                # Create log stream for function
                    "logs:PutLogEvents"                    # Write log events
                ]      
                Effect = "Allow"
                Resource = "arn:aws:logs:*:*:*"           # All CloudWatch Logs resources
            }
        ]
    })
}

# IAM role for the Lambda function
resource "aws_iam_role" "lambda_role" {
    name = "lambda_role_ssm_sns"                          # Descriptive role name
    
    # Trust policy allowing Lambda service to assume this role
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"                  # Allow role assumption
                Effect = "Allow"
                Sid = ""                                   # Empty SID
                Principal = {
                    Service = "lambda.amazonaws.com"       # Lambda service principal
                }
            }
        ]
    })
}

# Attach the policy to the role
resource "aws_iam_policy_attachment" "lamba_role_policy_attachment" {
    name = "lambda_ssm_sns"                               # Attachment name
    roles = [aws_iam_role.lambda_role.name]               # Role to attach policy to
    policy_arn = aws_iam_policy.lambda_policy.arn         # Policy to attach
}
