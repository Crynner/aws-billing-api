resource "aws_iam_role" "lambda-access-rds-sqs" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  description = "Role for Lambdas to access RDS and SQS services"
  name_prefix = "lambda-access-rds-sqs"
}

resource "aws_iam_role_policy" "lambda_rds_inline" {
  name = "lambda-access-rds"
  policy = jsonencode({
    Statement = [{
      Action   = "secretsmanager:GetSecretValue"
      Effect   = "Allow"
      Resource = aws_db_instance.billing-db.master_user_secret[0].secret_arn
    }]
    Version = "2012-10-17"
  })
  role = aws_iam_role.lambda-access-rds-sqs.name
}

resource "aws_iam_role_policy" "lambda_sqs_inline" {
  name = "lambda-access-sqs"
  policy = jsonencode({
    Statement = [{
      Action   = ["sqs:*"]
      Effect   = "Allow"
      Resource = aws_sqs_queue.billing-sqs.arn
      Sid      = "VisualEditor0"
    }]
    Version = "2012-10-17"
  })
  role = aws_iam_role.lambda-access-rds-sqs.name
}

resource "aws_iam_role" "billing-daily-scheduler" {
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
  description = "Role for Scheduler daily"
  name        = "billing-daily-scheduler"
}

resource "aws_iam_role_policy" "scheduler-lambda-inline" {
  name = "scheduler-access-lambda"
  policy = jsonencode({
    Statement = [{
      Action   = "lambda:InvokeFunction"
      Effect   = "Allow"
      Resource = aws_lambda_function.billing-daily-query.arn
    }]
    Version = "2012-10-17"
  })
  role = aws_iam_role.billing-daily-scheduler.name
}

