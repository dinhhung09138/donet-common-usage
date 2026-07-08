# Lab: Azure Entra ID — App Registration & Permissions

## Objectives
- Đăng ký Web API và Client App trong Azure Entra ID (Azure AD)
- Expose API scopes và yêu cầu permissions
- Hiểu sự khác biệt giữa Delegated và Application permissions
- Cấu hình App Roles và sự khác biệt `scp` vs `roles` claim
- Phân biệt v1 vs v2 token endpoint

## Prerequisites
- Azure subscription với quyền tạo App Registrations
- Kiến thức OAuth2 cơ bản (Lab: `lab-oauth2-authorization-code-pkce`)

## Tasks

### Task 1: Tạo Web API App Registration
1. Azure Portal → Entra ID → App registrations → New registration
2. Name: `orders-api`, Supported account types: "Accounts in this org directory only"
3. **Expose an API**:
   - Application ID URI: `api://{client-id}` (auto-generated)
   - Add scope: `Orders.Read` (User + Admin consent)
   - Add scope: `Orders.Write` (Admin consent only)
4. **App roles** (cho Application permissions):
   - Create role: `Reports.View` (Members: Applications)
   - Create role: `Orders.Manage` (Members: Applications)

### Task 2: Tạo Client App Registration
```
Name: orders-client
Redirect URI: https://oauth.pstmn.io/v1/callback (cho Postman testing)
```

**API Permissions** (thêm permissions):
- My APIs → `orders-api` → Delegated: `Orders.Read`
- My APIs → `orders-api` → Application: `Reports.View`
- Grant admin consent (cần Global Admin hoặc Application Admin)

### Task 3: Protect API với Entra ID
```bash
dotnet add package Microsoft.Identity.Web
```

```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("RequireOrdersRead", policy =>
        policy.RequireClaim("scp", "Orders.Read"));  // Delegated

    options.AddPolicy("RequireReportsView", policy =>
        policy.RequireClaim("roles", "Reports.View"));  // Application
});
```

```json
{
  "AzureAd": {
    "Instance": "https://login.microsoftonline.com/",
    "TenantId": "{your-tenant-id}",
    "ClientId": "{orders-api-client-id}",
    "Audience": "api://{orders-api-client-id}"
  }
}
```

### Task 4: Hiểu scp vs roles claim
```json
// Delegated token (user logged in, scope granted by user):
{
  "sub": "user-object-id",
  "scp": "Orders.Read",  // Space-separated scopes
  "upn": "alice@company.com"
}

// Application token (no user, app-to-app):
{
  "oid": "app-object-id",
  "roles": ["Reports.View", "Orders.Manage"],  // App roles
  // NOTE: NO "scp" claim — this is application permission, not user permission
}
```

### Task 5: v1 vs v2 token endpoint
```json
// Manifest → accessTokenAcceptedVersion:
// null hoặc 1 → v1 endpoint (https://login.microsoftonline.com/{tenant}/oauth2/token)
// 2 → v2 endpoint (https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token)
```

Sự khác biệt quan trọng:
- v1: audience = `https://management.azure.com/` (resource URI)
- v2: audience = `api://{client-id}` (Application ID URI)
- v2: scopes = `api://{client-id}/Orders.Read` (full qualified)
- v2: roles claim luôn là array (v1 có thể là string nếu 1 role)

### Task 6: Test với Postman
1. Collection → Authorization → OAuth 2.0
2. Grant Type: Authorization Code (with PKCE)
3. Auth URL: `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize`
4. Token URL: `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token`
5. Scope: `api://{client-id}/Orders.Read openid profile`
6. Lấy token → gọi API → kiểm tra 200 vs 403

### Task 7: Client Credentials từ code
```csharp
// app-to-app: lấy Application token
var app = ConfidentialClientApplicationBuilder
    .Create(clientId)
    .WithClientSecret(clientSecret)
    .WithAuthority($"https://login.microsoftonline.com/{tenantId}")
    .Build();

var result = await app.AcquireTokenForClient(
    new[] { "api://{orders-api-client-id}/.default" })
    .ExecuteAsync();

// .default scope = tất cả Application permissions đã được admin consent
```

## Expected Output
- 2 App Registrations: `orders-api` và `orders-client`
- Postman lấy được Delegated token (user login) → `scp: Orders.Read`
- Code lấy được Application token → `roles: ["Reports.View"]`
- API trả 200 với đúng permission, 403 với thiếu permission
- Manifest hiển thị `accessTokenAcceptedVersion: 2`

## Key Concepts
- **App Registration**: Azure AD representation của application
- **Delegated permission**: user grants access on their behalf (requires user login)
- **Application permission**: app acts as itself, no user (requires admin consent)
- **scp claim**: delegated scopes trong token (space-separated string)
- **roles claim**: app roles (array)
- **Admin consent**: Global Admin approve permissions cho tất cả users trong tenant
- **.default scope**: request tất cả permissions đã được pre-consented

## Resources
- [Register app in Microsoft identity platform](https://learn.microsoft.com/en-us/entra/identity-platform/quickstart-register-app)
- [Permissions and consent](https://learn.microsoft.com/en-us/entra/identity-platform/permissions-consent-overview)
- [App roles vs scopes](https://learn.microsoft.com/en-us/entra/identity-platform/howto-add-app-roles-in-apps)
- [Microsoft identity platform tokens](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens)
