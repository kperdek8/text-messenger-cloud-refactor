resource "aws_sns_topic" "email_notifications" {
  name = var.notification_topic
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.email_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_endpoint
}
