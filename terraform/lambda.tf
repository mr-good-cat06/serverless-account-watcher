data "archive_file" "lambda" {
    
    type = "zip"
    source_dir = "./../code"
    output_path = "$./../code/lambda.zip"
}

resource "aws_lambda_function" "lambda_for_alerting" {
    function_name = "lambda_for_alerting"
    filename = data.archive_file.lambda.output_path
    role = "${aws_iam_role.lambda_role_ssm_sns_cw.arn}"
    runtime = "nodejs18.x"
    handler = "lambda.handler"
    architectures = [ "x86_64" ]
    source_code_hash = data.archive_file.lambda.output_base64sha256

    logging_config {
      log_format = "Text"

    }
    depends_on = [ aws_iam_role.lambda_role_ssm_sns_cw ]

}

output "lambda_arn" {
    value = aws_lambda_function.lambda_for_alerting.arn
}
