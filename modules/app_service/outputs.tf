output "container_id" {
  description = "ID of the created container."
  value       = docker_container.service.id
}

output "container_name" {
  description = "Name of the created container."
  value       = docker_container.service.name
}

output "ip_address" {
  description = "Primary IP address of the container in the Docker network."
  value       = docker_container.service.network_data[0].ip_address # Assumes it's connected to at least one network
}