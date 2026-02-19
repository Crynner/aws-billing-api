resource "aws_scheduler_schedule" "billing-daily" {
  description         = "Runs the billing query lambda daily"
  group_name          = aws_scheduler_schedule_group.billing-schedule-group.name
  name                = "billing-daily"
  schedule_expression = "rate(1 days)"
  flexible_time_window {
    maximum_window_in_minutes = 10
    mode                      = "FLEXIBLE"
  }
  target {
    arn      = aws_lambda_function.billing-daily-query.arn
    role_arn = aws_iam_role.billing-daily-scheduler.arn
    retry_policy {
      maximum_event_age_in_seconds = 43200
      maximum_retry_attempts       = 20
    }
  }
}

resource "aws_scheduler_schedule_group" "billing-schedule-group" {
  name = "billing-schedule-group"
}

