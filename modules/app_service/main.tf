resource "docker_container" "service" {
  name  = var.service_name
  image = var.image
  restart = var.restart_policy

  dynamic "ports" {
    for_each = var.ports_mapping
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }

  networks_advanced {
    name    = var.network_id # Here we pass network ID, not name directly
    aliases = [var.service_name]
  }
  
  env = [for k, v in var.env_vars : "${k}=${v}"]

  dynamic "volumes" {
    for_each = var.volumes_mapping
    content {
      host_path      = volumes.value.host_path
      volume_name    = volumes.value.volume_name
      container_path = volumes.value.container_path
      read_only      = volumes.value.read_only
    }
  }

  command = var.command

  labels = var.labels
}