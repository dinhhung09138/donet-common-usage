# Lab: OAuth2 — Client Credentials Flow (Service-to-Service)

## Objectives
- Implement Client Credentials flow cho machine-to-machine authentication
- Tạo `ClientCredentialsDelegatingHandler` với token cache
- Gọi nhiều APIs với scopes khác nhau từ một service
- Client secret rotation mà không cần downtime
- Benchmark: với và không có token cache

## Prerequisites
- Lab: `lab-identity-server-quickstart`

## Tasks

### Task 1: IdentityServer — cấu hình M2M client
```csharp
new Client
{
    ClientId = "fulfillment-service",
    ClientName = "Fulfillment Service",
    AllowedGrantTypes = GrantTypes.ClientCredentials,
    ClientSecrets =
    {
        new Secret("secret-v1".Sha256()) { Expiration = DateTime.UtcNow.AddMonths(3) },
        // Rotation: thêm secret mới trước khi xóa cái cũ
        // new Secret("secret-v2".Sha256()) { Expiration = DateTime.UtcNow.AddMonths(6) }
    },
    AllowedScopes = { "orders:read", "inventory:read", "inventory:write" },
    AccessTokenLifetime = 3600  // 1 hour
}
```

### Task 2: Token service với cache
```csharp
public interface ITokenService
{
    Task<string> GetTokenAsync(string scope);
}

public class CachedTokenService : ITokenService
{
    private readonly IDiscoveryCache _discoveryCache;
    private readonly IMemoryCache _cache;
    private readonly ClientCredentialsSettings _settings;

    public async Task<string> GetTokenAsync(string scope)
    {
        var cacheKey = $"token:{_settings.ClientId}:{scope}";

        if (_cache.TryGetValue(cacheKey, out string? cachedToken))
            return cachedToken!;

        // Fetch new token
        var disco = await _discoveryCache.GetAsync();
        var client = new HttpClient();

        var response = await client.RequestClientCredentialsTokenAsync(
            new ClientCredentialsTokenRequest
            {
                Address = disco.TokenEndpoint,
                ClientId = _settings.ClientId,
                ClientSecret = _settings.ClientSecret,
                Scope = scope
            });

        if (response.IsError)
            throw new InvalidOperationException($"Token request failed: {response.Error}");

        // Cache với buffer: expire 60s trước actual expiry
        var expiresIn = response.ExpiresIn - 60;
        _cache.Set(cacheKey, response.AccessToken,
            TimeSpan.FromSeconds(expiresIn));

        return response.AccessToken!;
    }
}
```

### Task 3: DelegatingHandler — tự động attach token
```csharp
public class ClientCredentialsDelegatingHandler : DelegatingHandler
{
    private readonly ITokenService _tokenService;
    private readonly string _scope;

    public ClientCredentialsDelegatingHandler(ITokenService tokenService, string scope)
    {
        _tokenService = tokenService;
        _scope = scope;
    }

    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request, CancellationToken cancellationToken)
    {
        var token = await _tokenService.GetTokenAsync(_scope);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return await base.SendAsync(request, cancellationToken);
    }
}
```

### Task 4: Đăng ký nhiều typed clients với scopes khác nhau
```csharp
// Đăng ký token service
builder.Services.Configure<ClientCredentialsSettings>(
    builder.Configuration.GetSection("ClientCredentials"));
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<ITokenService, CachedTokenService>();

// OrdersApi client — chỉ cần orders:read
builder.Services.AddTransient<OrdersApiHandler>(sp =>
    new ClientCredentialsDelegatingHandler(
        sp.GetRequiredService<ITokenService>(), "orders:read"));

builder.Services.AddHttpClient<IOrdersApiClient, OrdersApiClient>(client =>
    client.BaseAddress = new Uri("https://localhost:7001"))
    .AddHttpMessageHandler<OrdersApiHandler>();

// InventoryApi client — cần inventory:read + inventory:write
builder.Services.AddTransient<InventoryApiHandler>(sp =>
    new ClientCredentialsDelegatingHandler(
        sp.GetRequiredService<ITokenService>(), "inventory:read inventory:write"));

builder.Services.AddHttpClient<IInventoryApiClient, InventoryApiClient>(client =>
    client.BaseAddress = new Uri("https://localhost:7002"))
    .AddHttpMessageHandler<InventoryApiHandler>();
```

### Task 5: Sử dụng trong service
```csharp
public class FulfillmentService
{
    private readonly IOrdersApiClient _ordersClient;
    private readonly IInventoryApiClient _inventoryClient;

    public async Task FulfillOrderAsync(string orderId)
    {
        // Token tự động được attach bởi DelegatingHandler
        var order = await _ordersClient.GetOrderAsync(orderId);
        await _inventoryClient.ReserveItemsAsync(order.Items);

        // Log để verify cache:
        _logger.LogInformation("Order {OrderId} fulfilled", orderId);
    }
}
```

### Task 6: Client Secret Rotation (zero downtime)
```
Strategy — overlapping secrets:
1. IdentityServer hiện có: secret-v1 (expires in 30 days)
2. Thêm secret-v2 vào IdentityServer (cả 2 đều active)
3. Update FulfillmentService config: ClientSecret = secret-v2
4. Verify service hoạt động tốt với secret-v2
5. Xóa secret-v1 khỏi IdentityServer
```

```csharp
// Vault-based rotation với Azure Key Vault:
// 1. Key Vault Secrets → tạo version mới
// 2. App reload config (không cần restart)
// 3. IdentityServer nhận được secret mới từ Key Vault
```

### Task 7: Benchmark — cache impact
```csharp
[Benchmark]
public async Task WithoutCache()
{
    // Mỗi request lấy token mới từ IdentityServer
    for (int i = 0; i < 100; i++)
    {
        var token = await _noCache.GetTokenAsync("orders:read");
    }
    // ~100 HTTP requests to IdentityServer
}

[Benchmark]
public async Task WithCache()
{
    // Chỉ 1 request lần đầu, 99 request còn lại từ cache
    for (int i = 0; i < 100; i++)
    {
        var token = await _cached.GetTokenAsync("orders:read");
    }
    // ~1 HTTP request to IdentityServer
}
```

## Expected Output
- FulfillmentService gọi OrdersApi → 200, không cần code authentication
- FulfillmentService gọi InventoryApi → 200 với write permission
- 100 concurrent requests → token lấy 1 lần, 99 lần cache hit
- Log: "Token acquired from IdentityServer" chỉ 1 lần per TTL
- Secret rotation: deploy với secret-v2 → không interruption

## Key Concepts
- **Client Credentials**: grant type cho machine-to-machine, không có user context
- **Token cache**: cache token đến khi exp - buffer (60 seconds)
- **DelegatingHandler**: HttpClient middleware — clean separation of auth concern
- **IDiscoveryCache**: IdentityModel utility để cache OIDC discovery document
- **Scope per client**: mỗi HttpClient có scope riêng phù hợp với target API
- **Zero-downtime rotation**: thêm mới trước khi xóa cũ

## Resources
- [IdentityModel — Client Credentials](https://identitymodel.readthedocs.io/en/latest/client/token.html)
- [Token management for HttpClient](https://github.com/DuendeSoftware/Duende.AccessTokenManagement)
- [Client secret rotation](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-3-create-a-new-application-secret)
