

resource "aws_cloudwatch_dashboard" "billing-dashboard" {
  dashboard_body = jsonencode({
    widgets = [{
      properties = {
        metrics = [["AWS/SQS", "NumberOfMessagesSent", "QueueName", "billing-dlq"], [".", "ApproximateNumberOfMessagesVisible", ".", "billing-sqs"], [".", "NumberOfMessagesSent", ".", "."], [".", "ApproximateAgeOfOldestMessage", ".", "."]]
        stacked = false
        view    = "timeSeries"
      }
      type  = "metric"
      width = 6
      height = 6
      x     = 0
      y     = 0
      }, {
      properties = {
        logGroupPrefixes = {
          accountIds     = []
          logClass       = "STANDARD"
          logGroupPrefix = []
        }
        query   = "SOURCE \"/aws/lambda/billing-daily-query\" | SOURCE \"/aws/lambda/billing-api-get\" | SOURCE \"/aws/lambda/billing-api-post\" | SOURCE \"/aws/lambda/billing-init-db\" | SOURCE \"/aws/lambda/billing-process-payment\" |\nfields @timestamp, @log, @message\n| filter level = \"error\"\n| sort @timestamp desc\n| limit 30"
        queryBy = "logGroupName"
        stacked = false
        title   = "Log group: Billing Lambdas"
        view    = "table"
      }
      type  = "log"
      width = 10
      height = 6
      x     = 0
      y     = 6
    }]
  })
  dashboard_name = "billing-dashboard"
}