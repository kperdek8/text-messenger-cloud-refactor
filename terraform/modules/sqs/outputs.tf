output "queue_url" {
  description = "The URL of the created SQS queue"
  value       = aws_sqs_queue.queue.id
}