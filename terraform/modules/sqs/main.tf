resource "aws_sqs_queue" "queue" {
  name                       = var.name
  visibility_timeout_seconds = var.visibility_timeout_seconds
  delay_seconds              = var.delay_seconds
  message_retention_seconds  = var.message_retention_seconds
}