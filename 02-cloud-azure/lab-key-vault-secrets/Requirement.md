# Lab: Key Vault Secret Management

## Objectives

- Eliminate all secrets from application configuration and code
- Access Key Vault using managed identity (no client secrets or keys)
- Integrate Key Vault with ASP.NET Core configuration provider

## Tasks

- [ ] Create Azure Key Vault and store sample secrets
- [ ] Create a user-assigned managed identity
- [ ] Assign Key Vault Secrets User role to the managed identity
- [ ] Add Key Vault as a configuration provider in .NET (auto-reload on change)
- [ ] Access secrets via `IConfiguration` — no SDK calls in business logic
- [ ] Demonstrate local development with Azure CLI credentials
- [ ] Add Terraform to provision Key Vault + managed identity + role assignment

## Expected Output

.NET API with zero secrets in `appsettings.json`. All sensitive config from Key Vault. Local dev uses `az login`.

## Key Concepts Practiced

`Key Vault` · `Managed Identity` · `RBAC role assignment` · `Configuration provider` · `Zero-secret config`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
