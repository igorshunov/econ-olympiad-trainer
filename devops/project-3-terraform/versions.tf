# Версии провайдеров. Фиксируем минорные мажоры — необходимо для воспроизводимости.
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # State backend — рекомендуется S3-совместимое хранилище Yandex Object Storage,
  # чтобы state не лежал локально и был доступен команде. Раскомментируйте перед
  # production-использованием.
  #
  # backend "s3" {
  #   endpoints = { s3 = "https://storage.yandexcloud.net" }
  #   bucket    = "econ-terraform-state"
  #   key       = "econtrainer/prod.tfstate"
  #   region    = "ru-central1"
  #   skip_region_validation      = true
  #   skip_credentials_validation = true
  # }
}
