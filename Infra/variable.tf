variable "postgres_identifier" {
  description = "DB instance identifie"
  type        = string
}

variable "postgres_db_user_name" {
  description = "Username for the RDS MySQL instance"
  type        = string
}


variable "postgres_db_password" {
  description = "Password for the RDS MySQL instance"
  type        = string
  sensitive   = true
}

variable "postgres_db_name" {
  description = "Database name for the RDS MySQL instance"
  type        = string
}

