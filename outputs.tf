output "application_url" {
  description = "Main URL to access the application via Nginx."
  value       = "http://localhost:${var.external_nginx_port}"
}

output "database_internal_host" {
  description = "Internal Docker hostname for the PostgreSQL database."
  value       = module.db_service.container_name
}

output "database_internal_ip" {
  description = "Internal IP address of the PostgreSQL database container."
  value       = module.db_service.ip_address
}

output "backend_service_details" {
  description = "Details of the backend service instance(s)."
  value = [for s in module.backend_service : {
    name = s.container_name
    ip   = s.ip_address
  }]
}

output "generated_db_password" {
  description = "The auto-generated database password if one was not provided. Store this securely if needed."
  value       = local.db_password
  sensitive   = true
}