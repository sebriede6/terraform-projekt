variable "service_name" {
  description = "Name of the service and container."
  type        = string
}

variable "image" {
  description = "Docker image to use for the container."
  type        = string
}

variable "network_id" {
  description = "ID of the Docker network to connect to."
  type        = string
}

variable "ports_mapping" {
  description = "List of port mappings (e.g., [{ internal = 3000, external = 3001 }])."
  type = list(object({
    internal = number
    external = number
  }))
  default = []
}

variable "env_vars" {
  description = "Map of environment variables for the container."
  type        = map(string)
  default     = {}
}

variable "volumes_mapping" {
  description = "List of volume mappings (e.g., [{ host_path = \"/path\", container_path = \"/path\"}] or [{ volume_name = \"myvol\", container_path = \"/data\"}])."
  type = list(object({
    host_path      = optional(string)
    volume_name    = optional(string)
    container_path = string
    read_only      = optional(bool, false)
  }))
  default = []
}

variable "command" {
  description = "Command to run in the container."
  type        = list(string)
  default     = null
}

variable "restart_policy" {
  description = "Restart policy for the container."
  type        = string
  default     = "unless-stopped"
}

variable "labels" {
  description = "Labels to apply to the container."
  type        = map(string)
  default     = {}
}