resource "aws_iam_role_policy" "lambda_policy_ssm_sns" {
    name = "allow_lambda_ssm_policy"
    role = aws_iam_role.lambda_role.id
    policy = jsondecode({
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
            }
        ]
    })
}


resource "aws_iam_role" "lambda_role_ssm_sns" {
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

resource "aws_iam_policy_attachment" "lamba_ssm_sns" {
    name = "lambda_ssm_sns"
    roles = [aws_iam_role.lambda_role_ssm_sns.name]
    policy_arn = aws_iam_policy.lambda_policy_ssm_sns.arn
}

