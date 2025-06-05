resource "docker_network" "app_network" {
  name = local.network_name
  labels {
    label = "project"
    value = "terraform-docker-demo"
  }
}

resource "docker_volume" "db_data" {
  name = local.db_volume_name
  labels {
    label = "project"
    value = "terraform-docker-demo"
  }
}

resource "random_string" "db_password" {
  count   = lookup(var.db_credentials, "password", null) == null ? 1 : 0
  length  = 16
  special = true
}

resource "docker_image" "backend_app_image" {
  name = local.backend_image_name
  build {
    context    = "${path.module}/app_code/backend"
    dockerfile = "Dockerfile"
    tag        = [local.backend_image_name]
    labels     = local.common_tags # Dies ist eine direkte Map-Zuweisung und korrekt für docker_image
  }
  keep_locally = true
}

module "db_service" {
  source       = "./modules/app_service"
  service_name = local.db_container_name
  image        = var.db_postgres_image
  network_id   = docker_network.app_network.id
  env_vars = {
    POSTGRES_USER     = var.db_credentials.user
    POSTGRES_PASSWORD = local.db_password
    POSTGRES_DB       = var.db_credentials.db_name
  }
  volumes_mapping = [{
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql/data"
  }]
  labels = local.common_tags
}

module "backend_service" {
  count        = var.backend_replicas
  source       = "./modules/app_service"
  service_name = "${var.app_prefix}-backend-app-${count.index}"
  image        = docker_image.backend_app_image.name
  network_id   = docker_network.app_network.id
  env_vars = {
    PORT         = "3000"
    DATABASE_URL = "postgres://${var.db_credentials.user}:${local.db_password}@${module.db_service.container_name}:5432/${var.db_credentials.db_name}"
  }
  labels     = merge(local.common_tags, { instance = tostring(count.index) })
  depends_on = [module.db_service, docker_image.backend_app_image]
}

resource "docker_container" "nginx_proxy" {
  name  = local.nginx_container_name
  image = "nginx:alpine"
  ports {
    internal = 80
    external = var.external_nginx_port
  }
  networks_advanced {
    name    = docker_network.app_network.id
    aliases = [local.nginx_container_name]
  }

  provisioner "local-exec" {
    command = "echo '${replace(local.nginx_config_content, "\n", "\\n")}' > ${path.module}/tmp/${local.nginx_container_name}.conf"
  }

  volumes {
    host_path      = abspath("${path.module}/nginx_config/default.conf.tpl")
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }

  volumes {
    host_path      = abspath("${path.module}/app_code/frontend")
    container_path = "/usr/share/nginx/html/frontend"
    read_only      = true
  }

  dynamic "labels" {
    for_each = local.common_tags
    content {
      label = labels.key
      value = labels.value
    }
  }

  depends_on = [module.backend_service]
}

module "monitoring_dummy_service" {
  count        = var.deploy_monitoring_dummy ? 1 : 0
  source       = "./modules/app_service"
  service_name = local.monitoring_container_name
  image        = "alpine/git"
  network_id   = docker_network.app_network.id
  command      = ["sh", "-c", "echo 'Monitoring dummy started at $(date)' && tail -f /dev/null"]
  labels       = local.common_tags
}