variable "yc_token" {
  description = "OAuth token Yandex Cloud (или используйте Service Account через YC_PROFILE)"
  type        = string
  sensitive   = true
  default     = null
}

variable "yc_cloud_id" {
  description = "Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Folder ID"
  type        = string
}

variable "yc_zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-a"
}

variable "env" {
  description = "Среда (staging/production)"
  type        = string
  default     = "staging"
  validation {
    condition     = contains(["staging", "production"], var.env)
    error_message = "env должен быть staging или production."
  }
}

variable "instance_count" {
  description = "Сколько app-VM создаём. Для staging=1, prod=2 (за балансером)."
  type        = number
  default     = 1
}

variable "instance_cores" {
  type    = number
  default = 2
}

variable "instance_memory_gb" {
  type    = number
  default = 4
}

variable "instance_disk_gb" {
  type    = number
  default = 20
}

variable "instance_preemptible" {
  description = "Прерываемые VM — дешевле, но могут быть остановлены."
  type        = bool
  default     = true
}

variable "ssh_public_key" {
  description = "Публичный ssh-ключ deploy-пользователя для cloud-init"
  type        = string
}

variable "domain" {
  description = "Базовый домен (для записей DNS)"
  type        = string
  default     = "econ.example.ru"
}
