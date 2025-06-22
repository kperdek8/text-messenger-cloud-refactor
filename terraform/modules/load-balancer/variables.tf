variable "vpc_id" {
  description = "VPC id"
  type        = string
  default     = "vpc-03f83890770cf601e"
}

variable "subnet_ids" {
  description = "VPC id"
  type        = list(string)
  default     = ["subnet-067c4fef793582ca1", "subnet-0caa6754f16c670d1", "subnet-0123874b5fd028997" , "subnet-0f1bed8df8b8649a3", "subnet-04f6ebfa3a0c780fb", "subnet-03b4cc603aa595cb0"]
}


variable "security_group" {
  description = "Security group ID for the ECS services"
  type        = string
}