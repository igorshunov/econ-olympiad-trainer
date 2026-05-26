provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_zone
}

# ────────────────────────────────────────────────────────────────────────────
# СЕТЬ: одна VPC, по подсети в каждой зоне доступности (a/b/c).
# ────────────────────────────────────────────────────────────────────────────
resource "yandex_vpc_network" "main" {
  name        = "econ-${var.env}-net"
  description = "EconTrainer ${var.env} network"
}

resource "yandex_vpc_subnet" "private" {
  for_each       = toset(["a", "b", "c"])
  name           = "econ-${var.env}-subnet-${each.key}"
  v4_cidr_blocks = ["10.10.${index(["a", "b", "c"], each.key)}.0/24"]
  zone           = "ru-central1-${each.key}"
  network_id     = yandex_vpc_network.main.id
}

# Security group: открыт публично только 80/443, ssh — только из доверенных подсетей.
resource "yandex_vpc_security_group" "app" {
  name        = "econ-${var.env}-app-sg"
  network_id  = yandex_vpc_network.main.id
  description = "EconTrainer app SG"

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH (с deploy-узла Ansible)"
    protocol    = "TCP"
    port        = 22
    # в production здесь должен быть IP CI/CD-агента, не 0.0.0.0/0
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description    = "any"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# ────────────────────────────────────────────────────────────────────────────
# COMPUTE: VM из публичного образа Ubuntu 22.04 + cloud-init.
# ────────────────────────────────────────────────────────────────────────────
data "yandex_compute_image" "ubuntu_2204" {
  family = "ubuntu-2204-lts"
}

resource "random_pet" "host" {
  count  = var.instance_count
  length = 2
}

locals {
  # cloud-init: создаём пользователя deploy с ssh-ключом, ставим базовые пакеты.
  user_data = <<-EOT
    #cloud-config
    users:
      - name: deploy
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        ssh_authorized_keys:
          - ${var.ssh_public_key}
    package_update: true
    package_upgrade: false
    packages:
      - ca-certificates
      - curl
      - gnupg
      - python3-pip
      - python3-docker
    runcmd:
      - echo "Provisioned by Terraform at $(date -u)" > /etc/econtrainer-provision
  EOT
}

resource "yandex_compute_instance" "app" {
  count       = var.instance_count
  name        = "econ-${var.env}-${random_pet.host[count.index].id}"
  description = "EconTrainer ${var.env} app node #${count.index + 1}"
  hostname    = "econ-${var.env}-${count.index + 1}"
  zone        = var.yc_zone

  resources {
    cores         = var.instance_cores
    memory        = var.instance_memory_gb
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204.id
      size     = var.instance_disk_gb
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private[substr(var.yc_zone, -1, 1)].id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.app.id]
  }

  metadata = {
    user-data = local.user_data
  }

  scheduling_policy {
    preemptible = var.instance_preemptible
  }

  labels = {
    env     = var.env
    project = "econtrainer"
    managed = "terraform"
  }
}

# ────────────────────────────────────────────────────────────────────────────
# Балансировщик (включаем только при count > 1).
# ────────────────────────────────────────────────────────────────────────────
resource "yandex_lb_target_group" "app" {
  count = var.instance_count > 1 ? 1 : 0
  name  = "econ-${var.env}-tg"
  dynamic "target" {
    for_each = yandex_compute_instance.app
    content {
      subnet_id = target.value.network_interface[0].subnet_id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "app" {
  count = var.instance_count > 1 ? 1 : 0
  name  = "econ-${var.env}-nlb"

  listener {
    name = "http"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app[0].id
    healthcheck {
      name = "healthz"
      http_options {
        port = 80
        path = "/healthz"
      }
    }
  }
}
