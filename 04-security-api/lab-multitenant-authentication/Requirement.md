# Lab: Multi-Tenant Authentication

## Objectives
- Implement tenant resolution từ subdomain, header, và JWT claim
- Per-tenant data isolation bằng EF Core global query filters
- Tích hợp Finbuckle.MultiTenant cho tenant management
- Per-tenant authentication authority
- Superadmin bypass tenant filters

## Prerequisites
- Lab: `lab-aspnet-core-identity-setup`
- Lab: `lab-jwt-tokens-deep-dive`

## Tasks

### Task 1: Cài đặt Finbuckle.MultiTenant
```bash
dotnet add package Finbuckle.MultiTenant.AspNetCore
dotnet add package Finbuckle.MultiTenant.EntityFrameworkCore
```

```csharp
// Program.cs
builder.Services.AddMultiTenant<TenantInfo>()
    .WithHostStrategy("{**}.{baseHost}")  // subdomain: tenant1.app.com
    .WithHeaderStrategy("X-Tenant-ID")   // header fallback
    .WithClaimStrategy("tenant_id")      // JWT claim fallback
    .WithEFCoreStore<TenantDbContext, TenantInfo>();  // Tenants stored in DB
```

### Task 2: TenantInfo model
```csharp
public class TenantInfo : ITenantInfo
{
    public string? Id { get; set; }
    public string? Identifier { get; set; }  // Used in tenant resolution (subdomain)
    public string? Name { get; set; }
    public string? ConnectionString { get; set; }  // Per-tenant DB (optional)
    public string? AuthorityUrl { get; set; }      // Per-tenant IdP
    public string? Plan { get; set; }  // "free", "pro", "enterprise"
    public bool IsActive { get; set; } = true;
}
```

### Task 3: Tenant resolution — 3 strategies
```
Strategy 1: Subdomain (preferred for SaaS)
  acme.orders-app.com → tenantId = "acme"
  globex.orders-app.com → tenantId = "globex"

Strategy 2: Header (for API clients)
  X-Tenant-ID: acme → tenantId = "acme"

Strategy 3: JWT claim (after authentication)
  JWT payload: {"tenant_id": "acme"} → tenantId = "acme"

Priority: Subdomain > Header > JWT claim
```

```csharp
// Đảm bảo tenant middleware chạy trước auth:
app.UseMultiTenant();  // BEFORE UseAuthentication
app.UseAuthentication();
app.UseAuthorization();
```

### Task 4: Per-tenant EF Core — global query filter
```csharp
public class AppDbContext : DbContext
{
    private readonly IMultiTenantContextAccessor<TenantInfo> _tenantAccessor;

    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Global query filter — TẤT CẢ queries tự động thêm WHERE tenant_id = current
        modelBuilder.Entity<Order>()
            .HasQueryFilter(o => o.TenantId == _tenantAccessor.MultiTenantContext!.TenantInfo!.Id);

        modelBuilder.Entity<Order>()
            .HasIndex(o => o.TenantId); // Index quan trọng cho performance!
    }
}

public class Order
{
    public Guid Id { get; set; }
    public required string TenantId { get; set; }  // Partition field
    public required string Description { get; set; }
    // ...
}
```

```csharp
// Mọi query TỰ ĐỘNG filter theo tenant — không cần thêm .Where(o => o.TenantId == ...)
var orders = await _db.Orders.ToListAsync();
// Thực ra tương đương: SELECT * FROM Orders WHERE TenantId = 'acme'
```

### Task 5: Per-tenant authentication authority
```csharp
// Mỗi tenant có thể có IdentityServer riêng
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Dynamic validator — check tenant's authority at runtime
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = async context =>
            {
                // Lấy tenant context
                var tenantContext = context.HttpContext
                    .GetMultiTenantContext<TenantInfo>();

                if (tenantContext?.TenantInfo?.AuthorityUrl != null)
                {
                    // Override authority dynamically per tenant
                    context.Options.Authority = tenantContext.TenantInfo.AuthorityUrl;
                }
            }
        };
        options.Authority = "https://default-idp.example.com"; // Default
        options.Audience = "orders-api";
    });
```

### Task 6: Tenant claims trong JWT
```csharp
// Khi issue token, thêm tenant_id vào claims
// (auth server cần biết user's tenant)
var claims = new[]
{
    new Claim(JwtRegisteredClaimNames.Sub, user.Id),
    new Claim("tenant_id", user.TenantId),  // ← tenant claim
    new Claim(JwtRegisteredClaimNames.Email, user.Email!)
};

// Validate tenant claim matches request tenant
options.Events = new JwtBearerEvents
{
    OnTokenValidated = async context =>
    {
        var tokenTenant = context.Principal?.FindFirstValue("tenant_id");
        var requestTenant = context.HttpContext
            .GetMultiTenantContext<TenantInfo>()?.TenantInfo?.Id;

        if (tokenTenant != requestTenant)
        {
            context.Fail("Token tenant does not match request tenant");
        }
    }
};
```

### Task 7: Superadmin — bypass tenant filter
```csharp
// Superadmin cần truy cập data của mọi tenant
public class AdminDbContext : AppDbContext
{
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Không gọi base.OnModelCreating() — không có global filters
        // Hoặc:
        modelBuilder.Entity<Order>().HasQueryFilter(null);  // Remove filter
    }
}

// Hoặc dùng IgnoreQueryFilters():
var allOrders = await _db.Orders
    .IgnoreQueryFilters()
    .Where(o => o.TenantId == targetTenantId)
    .ToListAsync();

// Guard: chỉ Superadmin role mới được gọi IgnoreQueryFilters
if (!user.IsInRole("SuperAdmin"))
    throw new ForbiddenException("Access denied");
```

### Task 8: Cross-tenant request detection
```csharp
// Middleware phát hiện và block cross-tenant access
app.Use(async (context, next) =>
{
    var tokenTenant = context.User.FindFirstValue("tenant_id");
    var requestTenant = context.GetMultiTenantContext<TenantInfo>()?.TenantInfo?.Id;

    if (tokenTenant != null && requestTenant != null
        && tokenTenant != requestTenant
        && !context.User.IsInRole("SuperAdmin"))
    {
        context.Response.StatusCode = 403;
        await context.Response.WriteAsJsonAsync(new
        {
            Error = "Cross-tenant access denied",
            TokenTenant = tokenTenant,
            RequestTenant = requestTenant
        });
        return;
    }

    await next();
});
```

## Expected Output
- `GET acme.app.com/orders` → chỉ thấy ACME orders
- `GET globex.app.com/orders` với token của acme user → 403
- `GET /orders` với `X-Tenant-ID: acme` → ACME orders
- SuperAdmin truy cập `GET globex.app.com/orders` → 200 (bypass filter)
- SQL query log: `SELECT * FROM Orders WHERE TenantId = 'acme'` (auto-injected)
- Thêm tenant mới → works immediately (config in DB, not code)

## Key Concepts
- **Finbuckle.MultiTenant**: library cho tenant resolution và context management
- **Global Query Filter**: EF Core filter tự động inject vào mọi query
- **Tenant resolution**: subdomain > header > claim (priority order)
- **IgnoreQueryFilters()**: bypass global filter — chỉ dùng cho superadmin
- **Per-tenant DB**: mỗi tenant có connection string riêng (strongest isolation)
- **Tenant claim**: bắt buộc trong JWT để cross-validate với request tenant

## Resources
- [Finbuckle.MultiTenant docs](https://www.finbuckle.com/MultiTenant)
- [EF Core global query filters](https://learn.microsoft.com/en-us/ef/core/querying/filters)
- [Multi-tenant SaaS patterns — Azure](https://learn.microsoft.com/en-us/azure/architecture/guide/multitenant/overview)
