variable "name" {
  description = "The name of the SQS queue"
  type        = string
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the queue in seconds"
  type        = number
  default     = 30
}

variable "delay_seconds" {
  description = "Delay seconds for messages"
  type        = number
  default     = 0
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds"
  type        = number
  default     = 86400 # 1 day
}