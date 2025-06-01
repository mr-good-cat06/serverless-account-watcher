resource "aws_iam_policy" "lambda_policy" {
    name = "allow_lambda_ssm_policy" 
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
            Action = [
                "ssm:GetParameter"
            ]      
            Effect = "Allow"
            Resource = "arn:aws:ssm:*:*:parameter/alerts/*"
            },
            {
            Action = [
                "sns:Publish"
            ]      
            Effect = "Allow"
            Resource = aws_sns_topic.alert-me.arn
            },
            {
            Action = [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]      
            Effect = "Allow"
            Resource = "arn:aws:logs:*:*:*"
            }
        ]
    })
}


resource "aws_iam_role" "lambda_role" {
    name = "lambda_role_ssm_sns"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Sid = ""
            Principal = {
                Service = "lambda.amazonaws.com"
            }
            }
        ]
    })
}

resource "aws_iam_policy_attachment" "lamba_role_policy_attachment" {
    name = "lambda_ssm_sns"
    roles = [aws_iam_role.lambda_role.name]
    policy_arn = aws_iam_policy.lambda_policy.arn
}
