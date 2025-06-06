locals {
  network_name              = "${var.app_prefix}-network"
  db_volume_name            = "${var.app_prefix}-pgdata"
  backend_image_name        = "${var.app_prefix}-backend-app:latest"
  nginx_container_name      = "${var.app_prefix}-nginx-proxy"
  db_container_name         = "${var.app_prefix}-postgres-db"
  monitoring_container_name = "${var.app_prefix}-monitor-dummy"

  common_tags = {
    environment = "development"
    project     = var.app_prefix
    managed_by  = "terraform"
  }

  nginx_config_content = templatefile("${path.module}/nginx_config/default.conf.tpl", {
    backend_host = module.backend_service[0].container_name 
    backend_port = 3000                                     
  })

  db_password = lookup(var.db_credentials, "password", null) == null ? random_string.db_password[0].result : var.db_credentials["password"]
}
