# Lab: MSAL.NET — Token Acquisition & Microsoft.Identity.Web

## Objectives
- Dùng `Microsoft.Identity.Web` để protect ASP.NET Core API với Entra ID
- Implement On-Behalf-Of flow cho API-to-API calls
- Cấu hình distributed token cache với Redis
- Implement incremental consent cho sensitive scopes
- So sánh `ITokenAcquisition` vs MSAL directly

## Prerequisites
- Lab: `lab-entra-id-app-registration`
- Lab: `lab-caching-patterns` (Redis cơ bản)

## Tasks

### Task 1: Web API với Microsoft.Identity.Web
```bash
dotnet add package Microsoft.Identity.Web
dotnet add package Microsoft.Identity.Web.MicrosoftGraphBeta  # nếu dùng Graph
```

```csharp
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"))
    .EnableTokenAcquisitionToCallDownstreamApi()
    .AddDistributedTokenCaches();

builder.Services.AddStackExchangeRedisCache(options =>
    options.Configuration = builder.Configuration.GetConnectionString("Redis"));
```

### Task 2: On-Behalf-Of flow (OBO)
Scenario: Client → OrdersApi → InventoryApi  
OrdersApi cần gọi InventoryApi ON BEHALF OF user.

```csharp
// OrdersApi cần:
// 1. Có scope "access_as_user" được expose
// 2. Được grant "user_impersonation" cho InventoryApi

[Authorize]
[RequiredScope("Orders.Read")]
public class OrdersController : ControllerBase
{
    private readonly ITokenAcquisition _tokenAcquisition;
    private readonly HttpClient _inventoryClient;

    [HttpGet("{id}")]
    public async Task<IActionResult> Get(string id)
    {
        // Lấy token cho InventoryApi ON BEHALF OF current user
        string inventoryToken = await _tokenAcquisition
            .GetAccessTokenForUserAsync(
                new[] { "api://{inventory-api-id}/Inventory.Read" });

        _inventoryClient.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", inventoryToken);

        var inventory = await _inventoryClient.GetFromJsonAsync<InventoryResult>(
            $"/inventory/{id}");

        return Ok(new { Order = id, Inventory = inventory });
    }
}
```

### Task 3: App-only token (Client Credentials)
```csharp
// Background service cần gọi API không có user context
public class SyncService : BackgroundService
{
    private readonly ITokenAcquisition _tokenAcquisition;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        // App token — không có user
        string appToken = await _tokenAcquisition
            .GetAccessTokenForAppAsync("api://{orders-api-id}/.default");

        // Dùng token để gọi API
    }
}
```

### Task 4: Distributed token cache với Redis
```csharp
// Thêm sau AddMicrosoftIdentityWebApi():
.EnableTokenAcquisitionToCallDownstreamApi()
.AddDistributedTokenCaches();

// Cấu hình Redis:
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "localhost:6379";
    options.InstanceName = "TokenCache:";
});
```

MSAL tự động:
- Cache token theo `(user_id, scopes, tenant)` key
- Tái sử dụng token cho đến khi hết hạn - 5 phút
- Tự động refresh token khi gần expired

### Task 5: Incremental consent
```csharp
// Lần đầu login: chỉ cần scope cơ bản
[Authorize]
[HttpGet("profile")]
public IActionResult GetProfile()
{
    return Ok(User.Identity?.Name);
}

// Khi cần access sensitive resource — require thêm scope
[Authorize]
[HttpGet("export")]
public async Task<IActionResult> ExportData()
{
    try
    {
        string token = await _tokenAcquisition
            .GetAccessTokenForUserAsync(new[] { "Reports.Export" });
        // ...
    }
    catch (MicrosoftIdentityWebChallengeUserException ex)
    {
        // User chưa consent → redirect to consent page
        return Challenge(ex.MsalUiRequiredException, JwtBearerDefaults.AuthenticationScheme);
    }
}
```

### Task 6: Test và verify tokens
```bash
# Decode token để xem claims
# jwt.ms — Azure's token decoder

# Verify OBO: token từ client chứa user's identity
# App token: không có "scp" claim, chỉ có "roles"

# Check cache hit:
# Gọi /orders → gọi /orders lại → xem log "Token acquired from cache"
```

### Task 7: Custom token validation
```csharp
builder.Services.AddAuthentication()
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"),
        jwtBearerOptionsName: JwtBearerDefaults.AuthenticationScheme,
        subscribeToJwtBearerMiddlewareDiagnosticsEvents: true);

// Custom validation (VD: block specific tenant)
builder.Services.Configure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme, options =>
{
    var existingValidator = options.Events.OnTokenValidated;
    options.Events.OnTokenValidated = async context =>
    {
        await existingValidator(context);
        var tenantId = context.Principal?.FindFirst("tid")?.Value;
        if (tenantId == "blocked-tenant-id")
            context.Fail("Tenant not allowed");
    };
});
```

## Expected Output
- API protected với Entra ID, returns 401 without token
- OBO flow: user token → OrdersApi → InventoryApi với user's identity
- Redis cache: second call to same scope returns cached token
- Incremental consent: `/export` triggers consent dialog khi user chưa approve scope
- App-only token: background service gọi API thành công

## Key Concepts
- **ITokenAcquisition**: abstraction over MSAL, tích hợp với ASP.NET Core DI
- **On-Behalf-Of (OBO)**: API call downstream on behalf of incoming user
- **Distributed token cache**: share cache across instances (vs in-memory per-instance)
- **Incremental consent**: request scopes lazily, only when needed
- **MicrosoftIdentityWebChallengeUserException**: exception khi user cần consent
- **tid claim**: tenant ID trong token

## Resources
- [Microsoft.Identity.Web docs](https://github.com/AzureAD/microsoft-identity-web)
- [On-Behalf-Of flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-on-behalf-of-flow)
- [Token cache serialization](https://learn.microsoft.com/en-us/entra/msal/dotnet/how-to/token-cache-serialization)
- [Incremental consent](https://learn.microsoft.com/en-us/entra/identity-platform/incremental-consent-for-web-apis)
