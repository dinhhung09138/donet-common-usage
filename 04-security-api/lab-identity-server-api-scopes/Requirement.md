# Lab: IdentityServer — API Scopes & Audience Validation

## Objectives
- Định nghĩa ApiResource với multiple scopes chi tiết
- Validate `aud` claim trong resource API
- Implement scope-based policy trong resource API
- Phân biệt client A (read-only) và client B (read+write)
- Viết token viewer middleware để debug claims

## Prerequisites
- Lab: `lab-identity-server-quickstart`

## Tasks

### Task 1: Cấu hình ApiResource với scopes
```csharp
public static IEnumerable<ApiResource> ApiResources => new[]
{
    new ApiResource("orders-api", "Orders API")
    {
        // Mọi token cho "orders-api" phải có ít nhất 1 trong các scopes này
        Scopes = { "orders:read", "orders:write", "orders:admin" },
        // Claims được include trong access token khi audience = orders-api
        UserClaims = { JwtClaimTypes.Name, JwtClaimTypes.Email }
    },
    new ApiResource("inventory-api", "Inventory API")
    {
        Scopes = { "inventory:read", "inventory:write" }
    }
};

public static IEnumerable<ApiScope> ApiScopes => new[]
{
    new ApiScope("orders:read")   { DisplayName = "Read your orders" },
    new ApiScope("orders:write")  { DisplayName = "Create and update orders" },
    new ApiScope("orders:admin")  { DisplayName = "Manage all orders (admin only)" },
    new ApiScope("inventory:read"),
    new ApiScope("inventory:write")
};
```

### Task 2: Client A — read-only
```csharp
new Client
{
    ClientId = "client-a",
    AllowedGrantTypes = GrantTypes.ClientCredentials,
    ClientSecrets = { new Secret("secret-a".Sha256()) },
    AllowedScopes = { "orders:read", "inventory:read" }
    // KHÔNG có orders:write hoặc orders:admin
}
```

### Task 3: Client B — full access
```csharp
new Client
{
    ClientId = "client-b",
    AllowedGrantTypes = GrantTypes.ClientCredentials,
    ClientSecrets = { new Secret("secret-b".Sha256()) },
    AllowedScopes = { "orders:read", "orders:write", "inventory:read", "inventory:write" }
}
```

### Task 4: Resource API — validate audience
```csharp
// OrdersApi/Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = "https://localhost:5001";
        options.Audience = "orders-api";  // Validate aud claim
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = true,
            ValidAudiences = new[] { "orders-api" }
        };
    });

builder.Services.AddAuthorization(options =>
{
    // Scope policies
    options.AddPolicy("CanReadOrders", p =>
        p.RequireClaim("scope", "orders:read"));

    options.AddPolicy("CanWriteOrders", p =>
        p.RequireClaim("scope", "orders:write"));

    options.AddPolicy("IsOrdersAdmin", p =>
        p.RequireClaim("scope", "orders:admin"));
});
```

### Task 5: Secure endpoints
```csharp
app.MapGet("/orders", [Authorize("CanReadOrders")] async (IOrderRepository repo) =>
    Results.Ok(await repo.GetAllAsync()));

app.MapPost("/orders", [Authorize("CanWriteOrders")] async (
    CreateOrderRequest req, IOrderRepository repo) =>
{
    var order = await repo.CreateAsync(req);
    return Results.Created($"/orders/{order.Id}", order);
});

app.MapDelete("/orders/{id}", [Authorize("IsOrdersAdmin")] async (
    string id, IOrderRepository repo) =>
{
    await repo.DeleteAsync(id);
    return Results.NoContent();
});
```

### Task 6: Token viewer middleware (debug)
```csharp
app.Use(async (context, next) =>
{
    if (context.Request.Path.StartsWithSegments("/token-debug") &&
        context.User.Identity?.IsAuthenticated == true)
    {
        var claims = context.User.Claims
            .Select(c => new { c.Type, c.Value })
            .ToList();

        await context.Response.WriteAsJsonAsync(new
        {
            IsAuthenticated = true,
            Claims = claims,
            Scopes = context.User.FindFirst("scope")?.Value?.Split(' '),
            Audience = context.User.FindFirst("aud")?.Value
        });
        return;
    }
    await next();
});
```

### Task 7: Test matrix
```bash
# Client A — orders:read only
TOKEN_A=$(curl -s -X POST https://localhost:5001/connect/token \
  -d "grant_type=client_credentials&client_id=client-a&client_secret=secret-a&scope=orders:read" \
  | jq -r '.access_token')

# Should succeed
curl -H "Authorization: Bearer $TOKEN_A" https://localhost:7001/orders

# Should fail (403 — missing scope)
curl -H "Authorization: Bearer $TOKEN_A" -X POST \
  -d '{"item":"test"}' https://localhost:7001/orders

# Client B — orders:read + orders:write
TOKEN_B=$(curl -s -X POST https://localhost:5001/connect/token \
  -d "grant_type=client_credentials&client_id=client-b&client_secret=secret-b&scope=orders:read orders:write" \
  | jq -r '.access_token')

# Should succeed
curl -H "Authorization: Bearer $TOKEN_B" -X POST \
  -d '{"item":"test"}' https://localhost:7001/orders

# Token for wrong API (inventory token used for orders API)
TOKEN_WRONG=$(curl -s -X POST https://localhost:5001/connect/token \
  -d "...&scope=inventory:read" | jq -r '.access_token')

# Should fail (401 — wrong audience)
curl -H "Authorization: Bearer $TOKEN_WRONG" https://localhost:7001/orders
```

## Expected Output
- Client A: GET /orders → 200; POST /orders → 403; DELETE /orders/{id} → 403
- Client B: GET /orders → 200; POST /orders → 201; DELETE /orders/{id} → 403
- Inventory token used on Orders API → 401 (wrong audience)
- `/token-debug` → JSON với tất cả claims, scope split thành array
- Token decode tại jwt.ms → `aud: ["orders-api"]`

## Key Concepts
- **Audience (`aud`)**: resource API validates this = "intended recipient" of token
- **Scope claim**: space-separated string trong token `"orders:read orders:write"`
- **ApiResource**: groups scopes + sets audience; prevents token reuse across APIs
- **Scope-based policy**: `RequireClaim("scope", "orders:write")` — more granular than roles
- **Token for wrong audience**: 401 (not 403) — token invalid for this API

## Resources
- [Duende — defining resources](https://docs.duendesoftware.com/identityserver/v7/fundamentals/resources/api_resources/)
- [Duende — scopes](https://docs.duendesoftware.com/identityserver/v7/fundamentals/resources/api_scopes/)
- [Protecting APIs with JWT bearer](https://docs.duendesoftware.com/identityserver/v7/quickstarts/1_client_credentials/#creating-an-api)
