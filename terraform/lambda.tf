resource "terraform_data" "psycopg2-build" {
  provisioner "local-exec" {
    command = "bash /../lambdas/layers/psycopg2/build.sh"
  }
}

resource "aws_lambda_layer_version" "psycopg2" {
  compatible_architectures = ["x86_64"]
  filename                 = "../lambdas/layers/psycopg2/psycopg2.zip"
  layer_name               = "psycopg2"
  description              = "psycopg2-binary lib"
  compatible_runtimes      = ["python3.14"]
}

data "archive_file" "zip-billing-daily-query" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/billing-daily-query.py"
  output_path = "${path.module}/.build/billing-daily-query.zip"
}

data "archive_file" "zip-billing-init-db" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/billing-init-db.py"
  output_path = "${path.module}/.build/billing-init-db.zip"
}

data "archive_file" "zip-billing-process-payment" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/billing-process-payment.py"
  output_path = "${path.module}/.build/billing-process-payment.zip"
}

data "archive_file" "zip-billing-api-get" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/billing-api-get.py"
  output_path = "${path.module}/.build/billing-api-get.zip"
}

data "archive_file" "zip-billing-api-post" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/billing-api-post.py"
  output_path = "${path.module}/.build/billing-api-post.zip"
}

resource "aws_lambda_function" "billing-daily-query" {
  description    = "Lambda to check which accounts are due for billing"
  filename       = data.archive_file.zip-billing-daily-query.output_path
  function_name  = "billing-daily-query"
  handler        = "billing-daily-query.handler"
  layers         = [aws_lambda_layer_version.psycopg2.arn]
  role           = aws_iam_role.lambda-access-rds-sqs.arn
  runtime        = "python3.14"
  timeout        = 10
  environment {
    variables = {
      database = aws_db_instance.billing-db.username
      host     = aws_db_instance.billing-db.address
      port     = aws_db_instance.billing-db.port
      queue    = aws_sqs_queue.billing-sqs.url
      secret   = aws_db_instance.billing-db.master_user_secret[0].secret_arn
    }
  }
  ephemeral_storage {
    size = 512
  }
  logging_config {
    application_log_level = "INFO"
    log_format            = "JSON"
    log_group             = "/aws/lambda/billing-daily-query"
    system_log_level      = "INFO"
  }
  tracing_config {
    mode = "PassThrough"
  }
  vpc_config {
    security_group_ids = [aws_security_group.lambda-sg.id]
    subnet_ids         = [aws_subnet.billing-subnet-private1.id, aws_subnet.billing-subnet-private2.id]
  }
}

resource "aws_lambda_function" "billing-init-db" {
  description   = "Script for initialising db and other RDS tweaks"
  filename      = "../lambdas/billing-init-db.zip"
  function_name = "billing-init-db"
  handler       = "billing-init-db.handler"
  layers        = [aws_lambda_layer_version.psycopg2.arn]
  role          = aws_iam_role.lambda-access-rds-sqs.arn
  runtime       = "python3.14"
  timeout       = 10
  environment {
    variables = {
      database = aws_db_instance.billing-db.username
      host     = aws_db_instance.billing-db.address
      port     = aws_db_instance.billing-db.port
      secret   = aws_db_instance.billing-db.master_user_secret[0].secret_arn
    }
  }
  ephemeral_storage {
    size = 512
  }
  logging_config {
    application_log_level = "INFO"
    log_format            = "JSON"
    log_group             = "/aws/lambda/billing-init-db"
    system_log_level      = "INFO"
  }
  tracing_config {
    mode = "PassThrough"
  }
  vpc_config {
    security_group_ids = [aws_security_group.lambda-sg.id]
    subnet_ids         = [aws_subnet.billing-subnet-private1.id, aws_subnet.billing-subnet-private2.id]
  }
}

resource "aws_lambda_function" "billing-process-payment" {
  description   = "Script to process billing action on ledger and account state"
  filename      = "../lambdas/billing-process-payment.zip"
  function_name = "billing-process-payment"
  handler       = "billing-process-payment.handler"
  layers        = [aws_lambda_layer_version.psycopg2.arn]
  role          = aws_iam_role.lambda-access-rds-sqs.arn
  runtime       = "python3.14"
  timeout       = 10
  environment {
    variables = {
      database = aws_db_instance.billing-db.username
      host     = aws_db_instance.billing-db.address
      port     = aws_db_instance.billing-db.port
      secret   = aws_db_instance.billing-db.master_user_secret[0].secret_arn
    }
  }
  ephemeral_storage {
    size = 512
  }
  logging_config {
    application_log_level = "INFO"
    log_format            = "JSON"
    log_group             = "/aws/lambda/billing-process-payment"
    system_log_level      = "INFO"
  }
  tracing_config {
    mode = "PassThrough"
  }
  vpc_config {
    security_group_ids = [aws_security_group.lambda-sg.id]
    subnet_ids         = [aws_subnet.billing-subnet-private1.id, aws_subnet.billing-subnet-private2.id]
  }
}

resource "aws_lambda_function" "billing-api-get" {
  description   = "Lambda handler for API Gateway GET requests"
  filename      = "../lambdas/billing-api-get.zip"
  function_name = "billing-api-get"
  handler       = "billing-api-get.handler"
  layers        = [aws_lambda_layer_version.psycopg2.arn]
  role          = aws_iam_role.lambda-access-rds-sqs.arn
  runtime       = "python3.14"
  timeout       = 10
  environment {
    variables = {
      database = aws_db_instance.billing-db.username
      host     = aws_db_instance.billing-db.address
      port     = aws_db_instance.billing-db.port
      secret   = aws_db_instance.billing-db.master_user_secret[0].secret_arn
    }
  }
  ephemeral_storage {
    size = 512
  }
  logging_config {
    application_log_level = "INFO"
    log_format            = "JSON"
    log_group             = "/aws/lambda/billing-api-get"
    system_log_level      = "INFO"
  }
  tracing_config {
    mode = "PassThrough"
  }
  vpc_config {
    security_group_ids = [aws_security_group.lambda-sg.id]
    subnet_ids         = [aws_subnet.billing-subnet-private1.id, aws_subnet.billing-subnet-private2.id]
  }
}

resource "aws_lambda_function" "billing-api-post" {
  description   = "Lambda handler for API Gateway POST requests"
  filename      = "../lambdas/billing-api-post.zip"
  function_name = "billing-api-post"
  handler       = "billing-api-post.handler"
  layers        = [aws_lambda_layer_version.psycopg2.arn]
  role          = aws_iam_role.lambda-access-rds-sqs.arn
  runtime       = "python3.14"
  timeout       = 10
  environment {
    variables = {
      database = aws_db_instance.billing-db.username
      host     = aws_db_instance.billing-db.address
      port     = aws_db_instance.billing-db.port
      secret   = aws_db_instance.billing-db.master_user_secret[0].secret_arn
    }
  }
  ephemeral_storage {
    size = 512
  }
  logging_config {
    application_log_level = "INFO"
    log_format            = "JSON"
    log_group             = "/aws/lambda/billing-api-post"
    system_log_level      = "INFO"
  }
  tracing_config {
    mode = "PassThrough"
  }
  vpc_config {
    security_group_ids = [aws_security_group.lambda-sg.id]
    subnet_ids         = [aws_subnet.billing-subnet-private1.id, aws_subnet.billing-subnet-private2.id]
  }
}