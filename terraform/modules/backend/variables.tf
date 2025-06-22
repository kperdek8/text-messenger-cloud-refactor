variable "app_bucket_id" {
  description = "ID of the S3 bucket containing application files"
  type        = string
}

variable "backend_key" {
  description = "S3 key for the backend Dockerrun.aws.json file"
  type        = string
}

variable "security_group_name" {
  description = "Security group ID for the backend"
  type        = string
}

variable "db_endpoint" {
  description = "Endpoint of the database"
  type        = string
}

variable "db_port" {
  description = "Port of the database"
  type        = string
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "user_pool_id" {
  description = "ID of the Cognito user pool"
  type        = string
}

variable "user_pool_client_id" {
  description = "ID of the Cognito user client"
  type        = string
}

variable "aws_access_key_id" {
  type        = string
  description = "AWS access key ID"
}

variable "aws_secret_access_key" {
  type        = string
  description = "AWS secret access key"
}

variable "aws_session_token" {
  type        = string
  description = "AWS session token"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}