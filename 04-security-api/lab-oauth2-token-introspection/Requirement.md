# Lab: OAuth2 — Token Introspection & Reference Tokens

## Objectives
- Cấu hình IdentityServer phát reference tokens (opaque) thay JWT
- Implement introspection trong resource API
- Cache introspection responses để tối ưu performance
- Test immediate revocation: logout → 401 ngay lập tức
- So sánh JWT (stateless) vs Reference Token (revocable) tradeoffs

## Prerequisites
- Lab: `lab-identity-server-api-scopes`

## Tasks

### Task 1: JWT vs Reference Token
```
JWT (Self-contained):
✓ Stateless — resource server validate offline (không cần network call)
✓ Performance — không cần introspection call
✓ Scalable — không có single point of failure
✗ Không thể revoke ngay — phải đợi exp
✗ Token size lớn hơn
✗ Claims có thể stale (user info thay đổi trong session)

Reference Token (Opaque):
✓ Revocable ngay lập tức (logout → tất cả APIs trả 401 ngay)
✓ Token nhỏ (chỉ là handle, không có claims)
✓ Claims luôn fresh (server lookup mỗi lần)
✗ Requires introspection call to auth server (network dependency)
✗ Auth server là single point of failure
✗ Higher latency unless cached

When to use Reference Tokens:
✓ High security scenarios (banking, healthcare)
✓ Need immediate revocation (shared computers, security incidents)
✓ Compliance requirements
```

### Task 2: IdentityServer — cấu hình Reference Token
```csharp
// Config.cs
new Client
{
    ClientId = "secure-webapp",
    AllowedGrantTypes = GrantTypes.Code,
    RequirePkce = true,
    AccessTokenType = AccessTokenType.Reference,  // ← Reference token!
    // AccessTokenType = AccessTokenType.Jwt,      // ← JWT (default)
    AccessTokenLifetime = 3600,
    AllowOfflineAccess = true,  // Refresh tokens — bản thân cũng là reference tokens
    ClientSecrets = { new Secret("secure-secret".Sha256()) },
    AllowedScopes = { "openid", "profile", "orders:read", "orders:write" }
}
```

### Task 3: Resource API — dùng introspection thay JWT Bearer
```bash
dotnet add package IdentityModel.AspNetCore.OAuth2Introspection
```

```csharp
// OrdersApi/Program.cs
builder.Services.AddAuthentication(OAuth2IntrospectionDefaults.AuthenticationScheme)
    .AddOAuth2Introspection(options =>
    {
        options.Authority = "https://localhost:5001";
        options.ClientId = "orders-api";       // API resource credentials
        options.ClientSecret = "api-secret";    // Để authenticate introspection request

        // Cache để tránh introspection call mỗi request
        options.EnableCaching = true;
        options.CacheDuration = TimeSpan.FromMinutes(5);
    });
```

### Task 4: Introspection request/response
Khi nhận Bearer token, API tự động gọi:

```
POST https://localhost:5001/connect/introspect
Content-Type: application/x-www-form-urlencoded
Authorization: Basic b3JkZXJzLWFwaTphcGktc2VjcmV0

token=<reference_token_value>
```

```json
// Response — active token:
{
  "active": true,
  "sub": "alice-id",
  "scope": "orders:read orders:write",
  "client_id": "secure-webapp",
  "aud": "orders-api",
  "exp": 1735000000,
  "iat": 1734996400,
  "name": "Alice Smith",
  "email": "alice@example.com"
}

// Response — revoked/expired:
{
  "active": false
}
```

### Task 5: Cấu hình API resource credentials
```csharp
// IdentityServer — ApiResource cần có secret cho introspection
new ApiResource("orders-api", "Orders API")
{
    ApiSecrets = { new Secret("api-secret".Sha256()) },
    Scopes = { "orders:read", "orders:write" }
}
```

### Task 6: Demo immediate revocation
```csharp
// Test scenario:
// 1. Login → nhận reference token
// 2. GET /orders → 200 (token valid)
// 3. Logout / Revoke token
// 4. GET /orders → 401 (ngay lập tức — không cần đợi exp)

app.MapPost("/revoke", async (RevokeTokenRequest request,
    IHttpClientFactory factory, IDiscoveryCache disco) =>
{
    var discovery = await disco.GetAsync();
    var client = factory.CreateClient();

    var response = await client.RevokeTokenAsync(new TokenRevocationRequest
    {
        Address = discovery.RevocationEndpoint,
        ClientId = "secure-webapp",
        ClientSecret = "secure-secret",
        Token = request.Token,
        TokenTypeHint = OidcConstants.TokenTypes.AccessToken
    });

    return response.IsError
        ? Results.BadRequest(response.Error)
        : Results.Ok("Token revoked");
});
```

### Task 7: Cache control — fresh introspection khi cần
```csharp
// Trong một số trường hợp cần bypass cache (VD: sau revocation)
services.AddAuthentication()
    .AddOAuth2Introspection(options =>
    {
        options.EnableCaching = true;
        options.CacheDuration = TimeSpan.FromMinutes(5);

        // Custom cache key — include token trong key
        options.CacheKeyPrefix = "introspect_";

        // Sau khi revoke — invalidate cache
        // Hoặc dùng short cache TTL cho high-security scenarios
    });

// Performance test: với cache
// 1000 requests → 1 introspection call (first) + 999 cache hits
// Latency: ~0.1ms (cache) vs ~5-10ms (network)
```

## Expected Output
- Login → nhận reference token (opaque string, không decode được)
- `GET /orders` với token → API gọi introspection → 200
- Inspect PersistedGrants table → thấy reference token entry
- `POST /revoke` với token → token deleted from DB
- `GET /orders` ngay sau revoke → 401 (không đợi cache TTL)
- Cache test: log "Introspection cache hit" sau request đầu tiên

## Key Concepts
- **Reference token**: opaque handle, IdentityServer giữ actual token data
- **Introspection endpoint**: `POST /connect/introspect` — validate token + return claims
- **active: false**: revoked hoặc expired token
- **Cache duration**: tradeoff giữa revocation latency và performance
- **API resource secret**: credentials API dùng để authenticate introspection request
- **Token revocation**: RFC 7009 — `POST /connect/revocation`

## Resources
- [RFC 7662 — Token Introspection](https://www.rfc-editor.org/rfc/rfc7662)
- [Duende — reference tokens](https://docs.duendesoftware.com/identityserver/v7/tokens/reference/)
- [IdentityModel.AspNetCore.OAuth2Introspection](https://github.com/IdentityModel/IdentityModel.AspNetCore.OAuth2Introspection)
- [RFC 7009 — Token Revocation](https://www.rfc-editor.org/rfc/rfc7009)
