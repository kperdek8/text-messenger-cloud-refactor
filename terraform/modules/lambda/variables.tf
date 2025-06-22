variable "lambda_functions" {
  description = "List of Lambda function configurations"
  type = list(object({
    name        = string
    route       = string
    method      = string
    handler     = string
    runtime     = string
    env_vars    = optional(map(string), {})
    zip_path    = string
  }))
}

variable "vpc_subnet_ids" {
  description = "List of subnet IDs for Lambda to run in"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of security group IDs for Lambda"
  type        = list(string)
}

variable "execution_role_arn" {
  description = "IAM role ARN to be used by all Lambda functions"
  type        = string
}