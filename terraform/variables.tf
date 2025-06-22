variable "aws_access_key_id" {
  description = "AWS access key"
  type        = string
}

variable "aws_secret_access_key" {
  description = "AWS secret key"
  type        = string
}

variable "aws_session_token" {
  description = "AWS session token"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "global_db_username" {
  description = "Username for the database"
  type        = string
  default     = "dbuser"
  sensitive   = true
}

variable "global_db_password" {
  description = "Password for the database"
  type        = string
  default     = "dbpassword"
  sensitive   = true
}