data "archive_file" "lambda" {
    
    type = "zip"
    source_dir = "${path.module}/../code"
    output_path = "${path.module}/../code/lambda.zip"
}

resource "aws_lambda_function" "lambda_for_alerting" {
    function_name = "lambda_for_alerting"
    filename = data.archive_file.lambda.output_path
    role = "${aws_iam_role.lambda_role.arn}"
    runtime = "python3.9"
    handler = "lambda.lambda_handler"
    architectures = [ "x86_64" ]
    source_code_hash = data.archive_file.lambda.output_base64sha256

    logging_config {
      log_format = "Text"

    }
    depends_on = [ aws_iam_role.lambda_role ]

}
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/lambda_for_alerting"
  retention_in_days = 14
}


output "lambda_arn" {
    value = aws_lambda_function.lambda_for_alerting.arn
}
