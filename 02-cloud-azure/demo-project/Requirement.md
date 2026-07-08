# Demo Project: Cloud-Native Order Processing System

> A production-ready demo combining AKS · Service Bus · CosmosDB · Key Vault · GitHub Actions CI/CD

## Architecture

```
[API Gateway / Ingress]
        │
  [Order Service]  ──────────────────────► [Service Bus Topic]
  (AKS Pod)                                       │
        │                                  [Fulfillment Service]
  [CosmosDB]                               (AKS Pod, subscriber)
  (order storage)                                 │
                                           [CosmosDB]
                                           (fulfillment records)

All secrets from Key Vault via managed identity.
All infra provisioned by Terraform.
Deployed via GitHub Actions with OIDC.
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Runtime | .NET 9, ASP.NET Core Minimal API |
| Orchestration | AKS (Helm chart) |
| Messaging | Azure Service Bus (topic + subscription) |
| Database | Azure CosmosDB |
| Secrets | Azure Key Vault + Managed Identity |
| CI/CD | GitHub Actions + OIDC |
| IaC | Terraform |
| Observability | Application Insights + OpenTelemetry |

## Getting Started

### Prerequisites

- Azure subscription
- Azure CLI authenticated (`az login`)
- Terraform >= 1.5
- .NET 9 SDK
- Docker

### Deploy

```bash
# 1. Provision infrastructure
cd infra/terraform
terraform init && terraform apply

# 2. Build and push images
docker build -t <acr>/order-service:latest ./src/OrderService
az acr login --name <acr>
docker push <acr>/order-service:latest

# 3. Deploy to AKS
helm upgrade --install order-system ./helm \
  --set image.repository=<acr>/order-service \
  --set image.tag=latest
```

## Design Decisions

See `docs/adr/` for Architecture Decision Records explaining key design choices.

## Status

- [ ] Core implementation complete
- [ ] Architecture diagram finalized
- [ ] ADR documents written
- [ ] Cost estimate added to README
- [ ] Published on GitHub
