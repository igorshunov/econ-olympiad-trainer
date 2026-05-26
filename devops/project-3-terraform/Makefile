.PHONY: help init fmt validate plan apply destroy output inventory

TF ?= terraform

help:
	@echo "EconTrainer · Terraform (Project 3)"
	@echo ""
	@echo "make init       — terraform init"
	@echo "make fmt        — terraform fmt -recursive"
	@echo "make validate   — terraform validate"
	@echo "make plan       — terraform plan"
	@echo "make apply      — terraform apply -auto-approve"
	@echo "make destroy    — terraform destroy -auto-approve"
	@echo "make output     — terraform output"
	@echo "make inventory  — сгенерировать Ansible inventory из output'а"

init:
	$(TF) init

fmt:
	$(TF) fmt -recursive

validate: fmt
	$(TF) validate

plan:
	$(TF) plan

apply:
	$(TF) apply -auto-approve

destroy:
	$(TF) destroy -auto-approve

output:
	$(TF) output

inventory:
	@$(TF) output -raw ansible_inventory_snippet > ../project-2-ansible/inventory.generated.yml
	@echo "Inventory: ../project-2-ansible/inventory.generated.yml"
