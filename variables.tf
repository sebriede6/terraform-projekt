variable "app_prefix" {
  description = "Prefix for all resource names to ensure uniqueness."
  type        = string
  default     = "devstack"
}

variable "external_nginx_port" {
  description = "External port for the Nginx reverse proxy."
  type        = number
  default     = 8080
  }

variable "db_postgres_image" {
  description = "Docker image for PostgreSQL."
  type        = string
  default     = "postgres:17-alpine"
}

variable "db_credentials" {
  description = "Credentials for the database (user, password, db_name). Password will be auto-generated if not provided."
  type        = map(string)
  default = {
    user    = "admin"
    db_name = "appdb"
  }
  sensitive = true
}

variable "deploy_monitoring_dummy" {
  description = "Deploy a dummy monitoring echo container."
  type        = bool
  default     = false
}

variable "backend_replicas" {
  description = "Number of backend service replicas (for demonstration, not true load balancing here)."
  type        = number
  default     = 1
  validation {
    condition     = var.backend_replicas >= 1 && var.backend_replicas <= 3
    error_message = "Backend replicas must be between 1 and 3."
  }
}