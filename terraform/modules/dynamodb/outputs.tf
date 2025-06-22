output "notification_log_table" {
  value = aws_dynamodb_table.notification_log.name
}