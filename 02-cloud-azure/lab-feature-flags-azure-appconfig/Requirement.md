# Lab: Feature Flags với Azure App Configuration

## Objectives
- Provision Azure App Configuration bằng Terraform
- Connect ASP.NET Core app với App Configuration dùng Managed Identity
- Quản lý feature flags trực tiếp từ Azure portal UI
- Implement dynamic refresh — app tự cập nhật khi flag thay đổi (không restart)
- Kết hợp Targeting Filter với App Configuration

## Prerequisites
- Lab: `lab-feature-flags-targeting-filter`
- Lab: `lab-key-vault-secrets` (hiểu Managed Identity pattern)
- Lab: `lab-terraform-infra` (Terraform cơ bản)
- Azure subscription

## Tasks

### Task 1: Provision với Terraform
```hcl
# main.tf
resource "azurerm_app_configuration" "this" {
  name                = "appconfig-orders-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "free"  # hoặc "standard" cho geo-replication
}

# RBAC: App Service Managed Identity → App Configuration Data Reader
resource "azurerm_role_assignment" "appconfig_reader" {
  scope                = azurerm_app_configuration.this.id
  role_definition_name = "App Configuration Data Reader"
  principal_id         = azurerm_app_service.this.identity[0].principal_id
}
```

### Task 2: Cài packages
```bash
dotnet add package Microsoft.Azure.AppConfiguration.AspNetCore
dotnet add package Microsoft.FeatureManagement.AspNetCore
dotnet add package Azure.Identity
```

### Task 3: Connect App Configuration trong Program.cs
```csharp
builder.Host.ConfigureAppConfiguration((context, config) =>
{
    var endpoint = new Uri(builder.Configuration["AppConfig:Endpoint"]!);
    var credential = new DefaultAzureCredential(); // Managed Identity in Azure, az login locally

    config.AddAzureAppConfiguration(options =>
    {
        options.Connect(endpoint, credential)
            // Load tất cả config với prefix "Orders:"
            .Select("Orders:*", context.HostingEnvironment.EnvironmentName)
            .TrimKeyPrefix("Orders:")
            // Feature flags
            .UseFeatureFlags(ff =>
            {
                ff.Select("*"); // Load tất cả feature flags
                ff.CacheExpirationInterval = TimeSpan.FromSeconds(30);
            })
            // Dynamic refresh với sentinel key
            .ConfigureRefresh(refresh =>
            {
                refresh.Register("Sentinel", refreshAll: true)
                       .SetCacheExpiration(TimeSpan.FromSeconds(30));
            });
    });
});

// Đăng ký refresh middleware
app.UseAzureAppConfiguration();

builder.Services.AddFeatureManagement();
```

### Task 4: Sentinel Key Pattern
Thay vì watch từng key (tốn polling), dùng sentinel:
1. Thay đổi bất kỳ config/flag nào
2. Cập nhật `Sentinel` key (VD: increment version number)
3. App detect sentinel change → refresh toàn bộ config

```json
// Azure App Configuration keys:
// Orders:Database:ConnectionString  → "Server=prod..."
// Sentinel                          → "v5" (bump khi muốn trigger refresh)
// Feature flag: NewCheckoutFlow     → true/false
```

### Task 5: Quản lý Feature Flags từ Azure Portal
1. App Configuration → **Feature manager** → Create feature flag
2. Tên: `NewCheckoutFlow`, Description: "New checkout UI"
3. Thêm Targeting Filter: Users: `[alice@example.com]`, Groups: `[beta-testers]`
4. Bật/tắt từ portal → app tự cập nhật trong < 30 giây

### Task 6: Demo dynamic refresh
```csharp
app.MapGet("/config/demo", (IConfiguration config, IFeatureManager features) =>
{
    return Results.Ok(new
    {
        DatabaseTimeout = config["Database:Timeout"],
        NewCheckoutEnabled = features.IsEnabledAsync("NewCheckoutFlow").Result
    });
});
```

Workflow:
1. Gọi `/config/demo` → thấy `NewCheckoutEnabled: false`
2. Vào Azure portal → bật `NewCheckoutFlow`
3. Bump sentinel key: `Sentinel = "v2"`
4. Đợi ~30 giây
5. Gọi `/config/demo` → thấy `NewCheckoutEnabled: true` (không restart!)

### Task 7: Local development
```csharp
// Local: dùng az login (DefaultAzureCredential tự pick up)
// Hoặc dùng connection string:
if (context.HostingEnvironment.IsDevelopment())
{
    var connectionString = builder.Configuration.GetConnectionString("AppConfig");
    config.AddAzureAppConfiguration(connectionString);
}
```

## Expected Output
- Feature flag thay đổi trên Azure portal → app cập nhật trong < 30 giây
- Targeting filter hoạt động: `alice@example.com` thấy feature, others không
- `GET /config/demo` phản ánh state hiện tại từ Azure
- Managed Identity auth — không có connection string / secret trong code

## Key Concepts
- **Azure App Configuration**: centralized config store, managed service
- **Sentinel key**: single key để trigger bulk refresh, thay vì watch nhiều keys
- **CacheExpirationInterval**: tần suất check changes (tradeoff: latency vs API calls)
- **DefaultAzureCredential**: tự động chọn auth method phù hợp với environment
- **IConfigurationRefresher**: interface để trigger refresh thủ công
- **App Configuration vs Key Vault**: App Config cho non-secret config + flags; Key Vault cho secrets

## Resources
- [Azure App Configuration docs](https://learn.microsoft.com/en-us/azure/azure-app-configuration/overview)
- [Feature management in App Configuration](https://learn.microsoft.com/en-us/azure/azure-app-configuration/concept-feature-management)
- [Dynamic configuration refresh](https://learn.microsoft.com/en-us/azure/azure-app-configuration/enable-dynamic-configuration-aspnet-core)
- [App Configuration pricing](https://azure.microsoft.com/en-us/pricing/details/app-configuration/)
