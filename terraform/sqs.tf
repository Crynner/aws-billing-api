resource "aws_sqs_queue" "billing-sqs" {
  name = "billing-sqs"
}

resource "aws_sqs_queue" "billing-sqs-dlq" {
  name = "billing-dlq"
}

resource "aws_sqs_queue_policy" "billing-sqs-policy" {
    queue_url = aws_sqs_queue.billing-sqs.id
    policy    = jsonencode({
      Statement = [{
        Action    = "SQS:*"
        Effect    = "Allow"
        Principal = {
          AWS       = "*"
        }
        Resource  = aws_sqs_queue.billing-sqs.arn
      }]
      Version   = "2012-10-17"
  })
}

resource "aws_sqs_queue_policy" "billing-sqs-dlq-policy" {
    queue_url = aws_sqs_queue.billing-sqs-dlq.id
    policy    = jsonencode({
      Statement = [{
        Action    = "SQS:*"
        Effect    = "Allow"
        Principal = {
          AWS       = "*"
        }
        Resource  = aws_sqs_queue.billing-sqs-dlq.arn
      }]
      Version    = "2012-10-17"
  })
}

resource "aws_sqs_queue_redrive_policy" "billing-sqs-redrive" {
  queue_url      = aws_sqs_queue.billing-sqs.id
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.billing-sqs-dlq.arn
    maxReceiveCount     = 100
  })
}