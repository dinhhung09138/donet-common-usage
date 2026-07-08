# Lab: Azure Service Principal & Workload Identity

## Objectives
- Tạo và quản lý Service Principal cho non-human workloads
- So sánh client secret vs certificate authentication
- Implement federated credentials cho GitHub Actions (không cần secret)
- Hiểu khi nào dùng Service Principal vs Managed Identity
- Demo: GitHub Actions deploy Azure resource với OIDC federated credential

## Prerequisites
- Lab: `lab-entra-id-app-registration`
- Lab: `lab-terraform-infra` (Terraform basics)
- GitHub account + repository

## Tasks

### Task 1: Tạo Service Principal với Azure CLI
```bash
# Tạo SP và lấy credentials
az ad sp create-for-rbac \
  --name "github-actions-orders-deploy" \
  --role "Contributor" \
  --scopes "/subscriptions/{sub-id}/resourceGroups/rg-orders" \
  --sdk-auth  # Output AZURE_CREDENTIALS JSON

# Kết quả:
# {
#   "clientId": "...",
#   "clientSecret": "...",   # <-- bí mật, cần rotate định kỳ
#   "subscriptionId": "...",
#   "tenantId": "..."
# }
```

### Task 2: Authenticate với DefaultAzureCredential
```csharp
// DefaultAzureCredential tự động chọn auth method:
// 1. EnvironmentCredential (AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_TENANT_ID)
// 2. WorkloadIdentityCredential (AKS Workload Identity)
// 3. ManagedIdentityCredential (App Service, Azure Functions)
// 4. VisualStudioCredential (local dev)
// 5. AzureCliCredential (local dev, az login)
// ...

var credential = new DefaultAzureCredential();
var blobClient = new BlobServiceClient(
    new Uri("https://{account}.blob.core.windows.net"),
    credential);
```

```bash
# Local development:
az login
# DefaultAzureCredential tự động dùng AzureCliCredential
```

### Task 3: Certificate authentication (không dùng secret)
```bash
# Tạo self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
openssl pkcs12 -export -out certificate.pfx -inkey key.pem -in cert.pem

# Upload certificate lên App Registration
az ad sp credential reset \
  --id {sp-object-id} \
  --cert @cert.pem \
  --append
```

```csharp
// Authenticate với certificate
var certificate = new X509Certificate2("certificate.pfx", "password");
var credential = new ClientCertificateCredential(
    tenantId, clientId, certificate);

var secretClient = new SecretClient(
    new Uri("https://{vault}.vault.azure.net/"),
    credential);
```

### Task 4: Federated Credentials — GitHub Actions OIDC (không cần secret!)
```bash
# Tạo federated credential cho GitHub Actions
az ad app federated-credential create \
  --id {app-object-id} \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:your-org/your-repo:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

GitHub Actions workflow:
```yaml
name: Deploy
on:
  push:
    branches: [main]

permissions:
  id-token: write   # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          # NO client-secret needed!

      - name: Deploy Terraform
        run: |
          terraform init
          terraform apply -auto-approve
```

### Task 5: Managed Identity vs Service Principal
| | Managed Identity | Service Principal |
|---|---|---|
| **Secret management** | Azure managed, auto-rotate | Manual, you manage secrets |
| **Use case** | Azure resources (VMs, App Service, AKS) | External (GitHub, Jenkins, local) |
| **Setup** | Enable in portal, 1 click | Create SP, assign roles |
| **Local dev** | Cannot use directly | Yes (with env vars) |
| **Cost** | Free | Free |
| **Best practice** | Prefer for Azure-hosted workloads | For external workloads |

### Task 6: Terraform tạo và assign SP
```hcl
# Tạo Service Principal
data "azuread_service_principal" "existing" {
  display_name = "github-actions-orders-deploy"
}

# RBAC assignment
resource "azurerm_role_assignment" "sp_contributor" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_service_principal.existing.object_id
}
```

### Task 7: Audit và rotate secrets
```bash
# Xem credentials của SP
az ad sp credential list --id {object-id}

# Reset (rotate) client secret
az ad sp credential reset --id {object-id}
# → Lấy clientSecret mới, update GitHub secrets / Key Vault

# Xem tất cả role assignments cho SP
az role assignment list --assignee {object-id} --all
```

## Expected Output
- GitHub Actions deploy thành công với OIDC (không có client secret trong repository)
- `az login` local → code chạy được với DefaultAzureCredential
- Certificate authentication hoạt động thay thế client secret
- Service Principal chỉ có minimum required RBAC roles
- terraform apply thành công, resources created

## Key Concepts
- **Service Principal**: non-human identity trong Entra ID cho workloads
- **Federated Credential**: trust OIDC token từ external provider (GitHub, Kubernetes)
- **DefaultAzureCredential**: chain of credential providers, tries in order
- **OIDC workload identity**: GitHub issues JWT → exchange với Azure token, no secret stored
- **Least privilege**: SP chỉ có permissions cần thiết, không dùng Owner/Contributor trừ khi bắt buộc
- **Secret rotation**: client secrets expire, cần rotate trước expiry

## Resources
- [Workload Identity Federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [DefaultAzureCredential](https://learn.microsoft.com/en-us/dotnet/azure/sdk/authentication/credential-chains)
- [Service Principal vs Managed Identity](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview)
