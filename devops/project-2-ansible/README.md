# Проект №2 — Деплой Docker-образов с помощью Ansible

Курс: **DevOps для программистов** (Хекслет колледж).
Студент: Горшунов Игорь Станиславович, группа 15.ИСиП.23.О-ЗФ.С.1.ХК.

Деплой — приложение **EconTrainer** (фронтенд из дипломного проекта),
упакованное в Docker-образ в [Проекте №1](../project-1-docker-compose).

## Цель

Автоматизировать установку и обновление стека EconTrainer на одном или
нескольких удалённых Linux-хостах через Ansible — от чистой Ubuntu 22.04
до работающего production-домена с TLS.

## Что делает playbook

При запуске `make deploy` для каждого хоста из `inventory.yml`:

1. **Pre-tasks** — установить базовые пакеты (`ca-certificates`, `curl`, `gnupg`, `python3-docker`, `jq`).
2. **Роль `docker`** — добавить официальный репозиторий Docker, поставить `docker-ce`,
   `docker-buildx-plugin`, `docker-compose-plugin`. Включить службу.
3. **Роль `app`**:
   - создать `/opt/econtrainer/`;
   - отрендерить из шаблонов: `docker-compose.yml`, `.env` (с секретами из Vault, права 0600),
     `Caddyfile` с автоматическим Let's Encrypt;
   - `docker compose pull` свежий образ из GHCR;
   - `docker compose up -d` — поднять стек;
   - дождаться `/healthz → 200` (10 retries × 3s).
4. **Роль `monitoring`** (опционально, для группы `production`) — поднять отдельный
   `docker-compose` с Prometheus + node-exporter + Grafana.
5. **Post-tasks** — финальная проверка `/healthz` и сводка.

## Структура

```
project-2-ansible/
├── ansible.cfg                  — настройки (forks, pipelining, ControlPersist)
├── inventory.yml                — staging + production хосты с переменными
├── playbook.yml                 — главный playbook (3 роли + pre/post)
├── group_vars/all.yml           — общие переменные стека
├── requirements.yml             — community.docker, community.general
├── Makefile                     — setup/ping/syntax/check/deploy/staging/production
└── roles/
    ├── docker/
    │   └── tasks/main.yml       — apt-репо, docker-ce, плагины, группа docker
    ├── app/
    │   ├── tasks/main.yml       — рендер шаблонов, pull, up, healthcheck
    │   ├── handlers/main.yml    — Recreate stack по изменению шаблонов
    │   └── templates/           — docker-compose.yml.j2, env.j2, Caddyfile.j2
    └── monitoring/
        ├── tasks/main.yml       — Prom + node-exporter + Grafana
        ├── handlers/main.yml
        └── templates/monitoring-compose.yml.j2
```

## Подготовка к запуску

```bash
# 1. Зависимости (один раз)
make setup

# 2. Vault — пароли:
ansible-vault create group_vars/all.vault.yml
# Содержимое:
#   vault_postgres_password: "<сильный пароль>"
#   vault_grafana_password:  "<сильный пароль>"

# 3. SSH-ключ на хосты
ssh-keygen -t ed25519 -f ~/.ssh/econ_deploy_id_ed25519
ssh-copy-id -i ~/.ssh/econ_deploy_id_ed25519.pub deploy@<host>

# 4. Параметр VAULT_PASS:
echo '<моя-парольная-фраза>' > vault_pass_file && chmod 600 vault_pass_file
```

## Команды

```bash
make ping        # SSH-ping ко всем хостам
make syntax      # синтаксис-проверка playbook'a
make check       # dry-run, --check --diff (изменения не применяются)
make deploy      # реальный деплой на все
make staging     # только staging-окружение
make production  # только production (с monitoring=true)
```

## Идемпотентность

Все таски используют ansible-модули с `state:`, `update_cache: cache_valid_time`, и
рендеринг шаблонов привязан к handlers — повторный запуск playbook'а не вносит
изменений, если ничего не поменялось. Это позволяет безопасно запускать
`make deploy` сколько угодно раз.

## Ansible Vault

Секреты (пароль БД, пароль Grafana, ключи API) хранятся в
`group_vars/all.vault.yml` и шифруются `ansible-vault`. В репозиторий
коммитится зашифрованный файл. Для расшифровки на CI используется
`--vault-password-file=vault_pass_file`, который в свою очередь
выдаётся из секрета CI.

## CI-интеграция (план)

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
      - run: pip install ansible
      - run: ansible-galaxy install -r requirements.yml
      - run: echo "${{ secrets.VAULT_PASS }}" > vault_pass_file
      - run: ansible-playbook playbook.yml -l staging
```

## Лицензия

MIT.
