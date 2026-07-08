# Lab: Duende IdentityServer — Quickstart (In-Memory)

## Objectives
- Khởi tạo Duende IdentityServer với cấu hình in-memory
- Hiểu discovery document và các endpoints chuẩn
- Cấu hình 2 loại clients: machine-to-machine và interactive
- Lấy token từ cả 2 flows và validate
- Hiểu sự khác biệt giữa ApiScope và ApiResource

## Prerequisites
- Lab: `lab-jwt-tokens-deep-dive`
- Kiến thức OAuth2 cơ bản

## Tasks

### Task 1: Tạo IdentityServer project
```bash
dotnet new web -n IdentityServer
cd IdentityServer
dotnet add package Duende.IdentityServer
```

```csharp
// Program.cs
builder.Services.AddIdentityServer()
    .AddInMemoryIdentityResources(Config.IdentityResources)
    .AddInMemoryApiScopes(Config.ApiScopes)
    .AddInMemoryApiResources(Config.ApiResources)
    .AddInMemoryClients(Config.Clients)
    .AddTestUsers(Config.TestUsers)
    .AddDeveloperSigningCredential(); // Development only — file-based RSA key

app.UseIdentityServer();
```

### Task 2: Config — Resources, Scopes, Clients
```csharp
public static class Config
{
    // IdentityResources = claims về user (cho ID token)
    public static IEnumerable<IdentityResource> IdentityResources => new[]
    {
        new IdentityResources.OpenId(),   // sub claim
        new IdentityResources.Profile(),  // name, given_name, family_name
        new IdentityResources.Email()     // email
    };

    // ApiScopes = quyền truy cập API (cho access token)
    public static IEnumerable<ApiScope> ApiScopes => new[]
    {
        new ApiScope("orders:read", "Read orders"),
        new ApiScope("orders:write", "Create/update orders"),
        new ApiScope("inventory:read", "Read inventory")
    };

    // ApiResources = nhóm scopes thành 1 "resource" (để set audience)
    public static IEnumerable<ApiResource> ApiResources => new[]
    {
        new ApiResource("orders-api", "Orders API")
        {
            Scopes = { "orders:read", "orders:write" }
        }
    };

    // Clients = applications có thể lấy token
    public static IEnumerable<Client> Clients => new[]
    {
        // Client 1: Machine-to-Machine (no user)
        new Client
        {
            ClientId = "m2m-client",
            ClientName = "Machine to Machine Client",
            AllowedGrantTypes = GrantTypes.ClientCredentials,
            ClientSecrets = { new Secret("m2m-secret".Sha256()) },
            AllowedScopes = { "orders:read", "inventory:read" }
        },

        // Client 2: Interactive (user login)
        new Client
        {
            ClientId = "orders-web",
            ClientName = "Orders Web App",
            AllowedGrantTypes = GrantTypes.Code,
            RequirePkce = true,
            ClientSecrets = { new Secret("web-secret".Sha256()) },
            RedirectUris = { "https://localhost:7001/signin-oidc" },
            PostLogoutRedirectUris = { "https://localhost:7001/signout-callback-oidc" },
            AllowedScopes = { "openid", "profile", "email", "orders:read", "orders:write" },
            AllowOfflineAccess = true  // Refresh tokens
        }
    };

    // Test users (thay bằng ASP.NET Core Identity trong production)
    public static List<TestUser> TestUsers => new()
    {
        new TestUser
        {
            SubjectId = "alice-id",
            Username = "alice",
            Password = "alice",
            Claims =
            {
                new Claim(JwtClaimTypes.Name, "Alice Smith"),
                new Claim(JwtClaimTypes.Email, "alice@example.com"),
                new Claim(JwtClaimTypes.Role, "Manager")
            }
        },
        new TestUser
        {
            SubjectId = "bob-id",
            Username = "bob",
            Password = "bob",
            Claims = { new Claim(JwtClaimTypes.Name, "Bob Jones") }
        }
    };
}
```

### Task 3: Discovery Document
```bash
# Tự động expose tại:
GET https://localhost:5001/.well-known/openid-configuration

# Response:
{
  "issuer": "https://localhost:5001",
  "authorization_endpoint": "https://localhost:5001/connect/authorize",
  "token_endpoint": "https://localhost:5001/connect/token",
  "userinfo_endpoint": "https://localhost:5001/connect/userinfo",
  "jwks_uri": "https://localhost:5001/.well-known/openid-configuration/jwks",
  "end_session_endpoint": "https://localhost:5001/connect/endsession",
  "introspection_endpoint": "https://localhost:5001/connect/introspect",
  "grant_types_supported": ["authorization_code", "client_credentials", "refresh_token"],
  "scopes_supported": ["openid", "profile", "email", "orders:read", "orders:write"],
  ...
}
```

### Task 4: Lấy token — Client Credentials
```bash
# POST to token endpoint
curl -X POST https://localhost:5001/connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=m2m-client&client_secret=m2m-secret&scope=orders:read"

# Response:
{
  "access_token": "eyJhbGci...",
  "expires_in": 3600,
  "token_type": "Bearer",
  "scope": "orders:read"
}
```

### Task 5: Resource API validate token
```csharp
// OrdersApi (separate project)
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = "https://localhost:5001"; // IdentityServer URL
        options.Audience = "orders-api";  // ApiResource name
        // Tự động fetch signing keys từ /.well-known/jwks.json
    });

app.MapGet("/orders", [Authorize] () => new[] { "Order 1", "Order 2" });
```

### Task 6: Test scope-based access
```bash
# Token với orders:read → GET /orders → 200
# Token với orders:read → POST /orders → 403 (missing orders:write)
# No token → 401
```

```csharp
// Scope check trong API:
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("OrdersRead", p => p.RequireClaim("scope", "orders:read"));
    options.AddPolicy("OrdersWrite", p => p.RequireClaim("scope", "orders:write"));
});

app.MapGet("/orders", [Authorize("OrdersRead")] () => Results.Ok());
app.MapPost("/orders", [Authorize("OrdersWrite")] () => Results.Created("/orders/1", null));
```

### Task 7: ApiScope vs ApiResource — khi nào cần cả hai?
```
ApiScope: đơn vị permission ("orders:read")
ApiResource: nhóm scopes + set audience claim trong token

Nếu chỉ có ApiScope:
→ access token KHÔNG có "aud" claim = resource name
→ Resource API không validate audience

Nếu có ApiResource bao gồm ApiScope:
→ access token CÓ "aud": ["orders-api"]
→ Resource API validate: Audience = "orders-api"
→ Ngăn token của một API dùng cho API khác
```

## Expected Output
- IdentityServer chạy tại https://localhost:5001
- Discovery document trả đầy đủ endpoints
- `curl` Client Credentials → access token
- OrdersApi validate token, trả 200 với scope `orders:read`
- OrdersApi trả 403 với token thiếu scope `orders:write`
- Decode token tại jwt.ms → thấy `aud`, `scope`, `iss`

## Key Concepts
- **IdentityResource**: claims về user (openid, profile, email) → ID token
- **ApiScope**: quyền truy cập resource → access token scope claim
- **ApiResource**: logical API resource, nhóm scopes + set audience
- **TestUsers**: in-memory users cho development, replaced by Identity in production
- **AddDeveloperSigningCredential**: lưu RSA key vào file — KHÔNG dùng trong production
- **Discovery document**: auto-exposed URL cho clients tìm endpoints và signing keys

## Resources
- [Duende IdentityServer quickstart](https://docs.duendesoftware.com/identityserver/v7/quickstarts/1_client_credentials/)
- [Duende docs — resources](https://docs.duendesoftware.com/identityserver/v7/fundamentals/resources/)
- [Duende docs — clients](https://docs.duendesoftware.com/identityserver/v7/reference/models/client/)
- [IdentityServer vs Azure Entra ID](https://docs.duendesoftware.com/identityserver/v7/overview/packaging/)
