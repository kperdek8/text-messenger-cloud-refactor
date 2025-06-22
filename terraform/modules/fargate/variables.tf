variable "cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "region" {
  description = "AWS region"
  type = string
}

variable "subnet_ids" {
  description = "VPC id"
  type        = list(string)
  default     = ["subnet-067c4fef793582ca1", "subnet-0caa6754f16c670d1", "subnet-0123874b5fd028997" , "subnet-0f1bed8df8b8649a3", "subnet-04f6ebfa3a0c780fb", "subnet-03b4cc603aa595cb0"]
}

variable "target_groups" {
  description = "Load balancer target groups for each service"
  type = map(any)
}

variable "lb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  type        = string
}

variable "apigw_dns_name" {
  description = "The DNS name of the API Gateway"
  type        = string
}

variable "security_group" {
  description = "Security group ID for the ECS services"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the IAM role used by ECS tasks for execution"
  type        = string
}

variable "services" {
  description = "List of services to deploy"
  type = list(object({
    name           = string
    container_port = number
    image          = string
	count		   = number
    env_vars       = list(object({
      name  = string
      value = string
    }))
  }))
}