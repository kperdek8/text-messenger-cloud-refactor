variable "name" {
  description = "Name of the API Gateway"
  type        = string
  default	  = "Chat Messenger"
}

variable "region" {
  description = "AWS region"
  type        = string
  default	  = "Chat Messenger"
}


variable "cognito_app_client_id" {
  type        = string
}

variable "cognito_user_pool_id" {
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  type        = string
}

variable "routes" {
  description = "Map of path => { name = alphanumeric_name,method = GET/POST/etc, lambda_arn = arn of lambda }"
  type = map(object({
    name       = string
    path       = string
    method     = string
    lambda_arn = string
  }))
}