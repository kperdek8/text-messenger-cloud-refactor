variable "app_bucket_id" {
  description = "ID of the S3 bucket containing application files"
  type        = string
}

variable "frontend_key" {
  description = "S3 key for the frontend Dockerrun.aws.json file"
  type        = string
}

variable "backend_url" {
  description = "URL of the backend environment"
  type        = string
}