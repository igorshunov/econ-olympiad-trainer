# Проект №3 — Инфраструктура как код (Terraform)

Курс: **DevOps для программистов** (Хекслет колледж).
Студент: Горшунов Игорь Станиславович, группа 15.ИСиП.23.О-ЗФ.С.1.ХК.

## Цель

Заменить ручной клик-провижининг сервера на декларативное описание
инфраструктуры в Terraform. Один и тот же код развёртывает идентичные
staging- и production-окружения в Yandex Cloud, output отдаётся
проекту №2 (Ansible) для дальнейшей настройки софта.

## Архитектура

```
                          ┌──────────────────┐
                          │ Yandex Cloud SDK │
                          └──────────────────┘
                                   ▲
                                   │ tf provider
┌──────────────┐  init/plan/apply  │
│ terraform    │──────────────────▶│
└──────────────┘
                                   │
                ┌──────────────────┼──────────────────┐
                │                  │                  │
        ┌───────▼──────┐   ┌───────▼──────┐   ┌──────▼──────┐
        │ VPC + subnet │   │  Security    │   │ Compute     │
        │ (a/b/c zones)│   │  Group       │   │ Instance(s) │
        └──────────────┘   └──────────────┘   └─────────────┘
                                                      │
                                              ┌───────▼──────┐
                                              │ Network LB   │
                                              │ (count > 1)  │
                                              └──────────────┘
```

## Что описано

| Ресурс | Назначение |
|--------|------------|
| `yandex_vpc_network`         | приватная сеть проекта |
| `yandex_vpc_subnet × 3`      | подсети в зонах ru-central1-{a,b,c} |
| `yandex_vpc_security_group`  | SG: 80/443 публично, 22 — для CI |
| `yandex_compute_instance × N`| app-VM (cloud-init → user `deploy` + ssh-ключ) |
| `yandex_lb_target_group`     | таргеты — внутренние IP всех VM |
| `yandex_lb_network_load_balancer` | публичный балансировщик, /healthz |

`count` для app-VM управляется переменной `instance_count`. При `1`
балансировщик не создаётся (для staging), при `>1` — поднимается NLB.

## Структура

```
project-3-terraform/
├── versions.tf                   — required_version + providers + (закомм.) S3 state
├── variables.tf                  — все переменные (validation, sensitive)
├── main.tf                       — VPC + SG + Compute + LB
├── outputs.tf                    — IP-адреса, имена, sample inventory.yml для Ansible
├── terraform.tfvars.example      — пример переменных (НЕ коммитить terraform.tfvars)
├── templates/inventory.yml.tftpl — генератор Ansible-инвентаря из output'а
└── Makefile                      — init / fmt / validate / plan / apply / inventory
```

## Принципы IaC, которые здесь соблюдены

- **Декларативность** — желаемое состояние, а не последовательность команд.
- **Идемпотентность** — повторный `terraform apply` ничего не делает, если ничего не изменилось.
- **Версионирование** — провайдеры зафиксированы (`~> 0.130` для yandex).
- **State в backend** — конфигурация S3-бекенда подготовлена, осталось раскомментировать.
- **Variables + validation** — `var.env` принимает только `staging` или `production`.
- **No magic numbers** — все размеры VM, домены, имена-параметризованы.
- **Outputs как контракт** — IP-адреса и сгенерированный inventory.yml выдаются как output.
- **Sensitive флаг** — `yc_token` помечен `sensitive = true`.
- **DRY** — подсети созданы через `for_each`, VM — через `count + random_pet`.
- **Cloud-init** — конфигурация ОС (deploy-пользователь, ssh-ключ) описана в коде.

## Цикл «from zero to running»

```bash
# 1. Подготовка
cp terraform.tfvars.example terraform.tfvars
# Подставить yc_cloud_id, yc_folder_id, ssh_public_key

# 2. Terraform
make init
make validate
make plan        # увидите ~7 ресурсов
make apply       # развернёт VPC + SG + 1 VM (staging-default)
make output      # получите external IP

# 3. Передача в Ansible (Project №2)
make inventory   # сгенерирует ../project-2-ansible/inventory.generated.yml
cd ../project-2-ansible && make deploy
```

## Бэкенд state

Сейчас state хранится локально (`terraform.tfstate`) — годится для
демонстрации. Для production раскомментируйте `backend "s3"` в
`versions.tf` и создайте бакет в Yandex Object Storage. Это позволит
команде работать с одним state и автоматизировать deploy через CI.

## Расчёт стоимости

В файле `instance_preemptible = true` (по умолчанию) — это
прерываемые VM Yandex Cloud, **~3× дешевле** обычных, но могут быть
остановлены платформой. Для production выставите `false`.

## Расширение

- BD как managed-сервис (`yandex_mdb_postgresql_cluster`) вместо
  Postgres-контейнера на VM.
- Object Storage bucket для бэкапов БД.
- Cloud DNS — управление A-записями `econ.example.ru → LB-IP`.
- KMS для шифрования секретов.
- IAM — отдельный service account для CI с минимумом прав.

## Лицензия

MIT.
