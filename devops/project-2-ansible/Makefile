.PHONY: help setup ping deploy staging production check syntax facts

ANSIBLE ?= ansible
ANSIBLE_PLAYBOOK ?= ansible-playbook
VAULT_PASS ?= --vault-password-file=vault_pass_file

help:
	@echo "EconTrainer · Ansible deploy (Project 2)"
	@echo ""
	@echo "make setup       — установить роли/коллекции (requirements.yml)"
	@echo "make ping        — проверить SSH-доступ ко всем хостам"
	@echo "make syntax      — синтаксическая проверка playbook'а"
	@echo "make check       — dry-run полного деплоя (без изменений)"
	@echo "make deploy      — реальный деплой на все хосты"
	@echo "make staging     — деплой только в group=staging"
	@echo "make production  — деплой только в group=production"

setup:
	ansible-galaxy install -r requirements.yml

ping:
	$(ANSIBLE) all -m ansible.builtin.ping

syntax:
	$(ANSIBLE_PLAYBOOK) playbook.yml --syntax-check

check:
	$(ANSIBLE_PLAYBOOK) playbook.yml --check --diff $(VAULT_PASS)

deploy:
	$(ANSIBLE_PLAYBOOK) playbook.yml $(VAULT_PASS)

staging:
	$(ANSIBLE_PLAYBOOK) playbook.yml -l staging $(VAULT_PASS)

production:
	$(ANSIBLE_PLAYBOOK) playbook.yml -l production $(VAULT_PASS)

facts:
	$(ANSIBLE) all -m ansible.builtin.setup -a 'filter=ansible_distribution*'
