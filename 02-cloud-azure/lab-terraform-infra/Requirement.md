# Lab: Terraform Azure Infrastructure

## Objectives

- Provision a complete Azure environment with Terraform
- Use remote state (Azure Storage) for team collaboration
- Organize into reusable modules

## Tasks

- [ ] Create Terraform project structure: `main.tf`, `variables.tf`, `outputs.tf`
- [ ] Configure Azure provider and remote state backend (Azure Storage)
- [ ] **Pin provider versions** — run `terraform init`, commit `.terraform.lock.hcl` to source control; document why (prevents version drift across team members, analogous to `package-lock.json`)
- [ ] Create modules: `networking`, `aks`, `acr`, `servicebus`, `keyvault`, `cosmosdb`
- [ ] Provision: Resource Group, VNet, AKS, ACR, Service Bus, Key Vault, CosmosDB
- [ ] Configure managed identity and role assignments in Terraform
- [ ] Use `for_each` (not `count`) when creating multiple similar resources (e.g., RBAC role assignments) — understand why `for_each` is safer when the set changes
- [ ] Use Terraform workspaces for dev/staging/prod environments
- [ ] Add `terraform plan` as a GitHub Actions PR check
- [ ] **Terraform import** — manually create an Azure Resource Group in the portal, then import it into state using: (a) `terraform import azurerm_resource_group.example /subscriptions/.../resourceGroups/my-rg` and (b) `import` block syntax (Terraform 1.5+); verify with `terraform plan` showing "No changes"
- [ ] **Drift detection** — add a GitHub Actions scheduled workflow (nightly cron) that runs `terraform plan` against the dev workspace and opens a GitHub Issue if plan output is non-empty
- [ ] Document: how to run locally, how to destroy

## Expected Output

Terraform code that provisions the full environment in one `terraform apply`. State in Azure Storage. Module-based structure.

## Key Concepts Practiced

`Terraform` · `Remote state` · `Modules` · `Workspaces` · `Azure provider` · `RBAC in Terraform` · `.terraform.lock.hcl` · `terraform import` · `import block` · `Drift detection` · `for_each vs count` · `tfsec`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
