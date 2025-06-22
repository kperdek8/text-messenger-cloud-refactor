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

variable "db_identifier" {
  description = "Identifier name of the database"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the database"
  type        = string
}