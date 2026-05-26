output "instance_external_ips" {
  description = "Публичные IP всех app-VM"
  value       = [for inst in yandex_compute_instance.app : inst.network_interface[0].nat_ip_address]
}

output "instance_internal_ips" {
  description = "Внутренние IP всех app-VM"
  value       = [for inst in yandex_compute_instance.app : inst.network_interface[0].ip_address]
}

output "instance_names" {
  description = "Имена созданных VM"
  value       = [for inst in yandex_compute_instance.app : inst.name]
}

output "load_balancer_ip" {
  description = "IP сетевого балансировщика (если создан)"
  value       = length(yandex_lb_network_load_balancer.app) > 0 ? yandex_lb_network_load_balancer.app[0].listener[*].external_address_spec : []
}

output "vpc_id" {
  value = yandex_vpc_network.main.id
}

# Для генерации inventory.yml для Ansible (Project №2).
output "ansible_inventory_snippet" {
  description = "Сниппет для подстановки в Ansible inventory"
  value = templatefile("${path.module}/templates/inventory.yml.tftpl", {
    hosts = [for i, inst in yandex_compute_instance.app : {
      name = inst.name
      ip   = inst.network_interface[0].nat_ip_address
    }]
    env = var.env
  })
}
