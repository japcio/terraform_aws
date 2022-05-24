variable "db_username"  {
    description = "Username for the database"
    type        = string
    sensitive  = true
}

variable "db_password" {
    description = "Password for the database"
    type        = string
    sensitive   = true
}

variable "db_name" {
  description = "The name to use for the database"
  type        = string
  default     = "database_test"
}

