# =============================================================================
# lambda.tf - Lambda Function Configuration
# =============================================================================
# This file creates the Lambda function that processes EventBridge events
# and sends alerts via SNS and Slack webhooks.

# Create ZIP file from Lambda source code
data "archive_file" "lambda" {
    type = "zip"                                          # Archive type
    source_dir = "${path.module}/../code"                 # Source directory containing Lambda code
    output_path = "${path.module}/../code/lambda.zip"     # Output ZIP file path
}

# Lambda function resource
resource "aws_lambda_function" "lambda_for_alerting" {
    function_name = "lambda_for_alerting"                 # Lambda function name
    filename = data.archive_file.lambda.output_path       # ZIP file containing code
    role = "${aws_iam_role.lambda_role.arn}"             # IAM role ARN for execution
    runtime = "python3.9"                                # Python runtime version
    handler = "lambda.lambda_handler"                     # Entry point (file.function)
    architectures = [ "x86_64" ]                         # Processor architecture
    source_code_hash = data.archive_file.lambda.output_base64sha256  # For detecting code changes

    # Configure logging format
    logging_config {
      log_format = "Text"                                 # Use text-based logging
    }
    
    # Ensure IAM role exists before creating function
    depends_on = [ aws_iam_role.lambda_role ]
}

# CloudWatch Log Group for Lambda function logs
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/lambda_for_alerting"   # Standard Lambda log group naming
  retention_in_days = 14                                  # Retain logs for 2 weeks
}

# Output the Lambda function ARN for reference
output "lambda_arn" {
    value = aws_lambda_function.lambda_for_alerting.arn
}
