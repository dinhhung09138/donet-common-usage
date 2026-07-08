# Lab: ASP.NET Core Identity — Custom Claims & Policy-Based Auth

## Objectives
- Tạo custom `IUserClaimsPrincipalFactory` để thêm claims từ database
- Implement `IClaimsTransformation` để enrich claims sau JWT validation
- Xây dựng policy-based authorization với custom requirements
- Implement resource-based authorization (user chỉ thay đổi data của mình)
- Hiểu fat token vs thin token tradeoff

## Prerequisites
- Lab: `lab-aspnet-core-identity-setup`

## Tasks

### Task 1: Custom IUserClaimsPrincipalFactory
```csharp
public class AppUserClaimsPrincipalFactory : UserClaimsPrincipalFactory<ApplicationUser, IdentityRole>
{
    private readonly AppDbContext _db;

    protected override async Task<ClaimsIdentity> GenerateClaimsAsync(ApplicationUser user)
    {
        var identity = await base.GenerateClaimsAsync(user);

        // Thêm claims từ user object
        identity.AddClaim(new Claim("full_name", user.FullName));
        identity.AddClaim(new Claim("tenant_id", user.TenantId ?? "default"));

        // Thêm claims từ database (VD: subscription tier)
        var subscription = await _db.Subscriptions
            .Where(s => s.UserId == user.Id)
            .Select(s => s.Tier)
            .FirstOrDefaultAsync();

        if (subscription != null)
            identity.AddClaim(new Claim("subscription_tier", subscription));

        return identity;
    }
}

// Register:
builder.Services.AddScoped<IUserClaimsPrincipalFactory<ApplicationUser>, AppUserClaimsPrincipalFactory>();
```

### Task 2: IClaimsTransformation — enrich sau JWT validation
Hữu ích khi dùng external JWT (từ Entra ID, Duende) nhưng cần claims từ local DB.

```csharp
public class PermissionsClaimsTransformation : IClaimsTransformation
{
    private readonly IPermissionService _permissions;
    private readonly IMemoryCache _cache;

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return principal;

        // Cache theo userId để tránh DB hit mỗi request
        var permissions = await _cache.GetOrCreateAsync(
            $"permissions:{userId}",
            async entry =>
            {
                entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);
                return await _permissions.GetForUserAsync(userId);
            });

        var claimsIdentity = new ClaimsIdentity();
        foreach (var permission in permissions!)
            claimsIdentity.AddClaim(new Claim("permission", permission));

        principal.AddIdentity(claimsIdentity);
        return principal;
    }
}

// Register:
builder.Services.AddScoped<IClaimsTransformation, PermissionsClaimsTransformation>();
```

### Task 3: Policy-based authorization
```csharp
builder.Services.AddAuthorization(options =>
{
    // Simple claim check
    options.AddPolicy("PremiumOnly", policy =>
        policy.RequireClaim("subscription_tier", "premium", "enterprise"));

    // Custom requirement
    options.AddPolicy("CanExportReports", policy =>
        policy.Requirements.Add(new PermissionRequirement("reports:export")));

    // Combined
    options.AddPolicy("SeniorManager", policy =>
    {
        policy.RequireRole("Manager");
        policy.RequireClaim("experience_years", requirement =>
            int.TryParse(requirement, out var years) && years >= 5);
    });
});
```

### Task 4: Custom IAuthorizationRequirement
```csharp
public record PermissionRequirement(string Permission) : IAuthorizationRequirement;

public class PermissionHandler : AuthorizationHandler<PermissionRequirement>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        PermissionRequirement requirement)
    {
        var hasPermission = context.User
            .FindAll("permission")
            .Any(c => c.Value == requirement.Permission);

        if (hasPermission)
            context.Succeed(requirement);

        return Task.CompletedTask;
    }
}

// Register:
builder.Services.AddScoped<IAuthorizationHandler, PermissionHandler>();
```

### Task 5: Resource-based authorization
```csharp
public class OrderOwnerRequirement : IAuthorizationRequirement { }

public class OrderOwnerHandler : AuthorizationHandler<OrderOwnerRequirement, Order>
{
    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        OrderOwnerRequirement requirement,
        Order order)  // resource = order
    {
        var userId = context.User.FindFirstValue(ClaimTypes.NameIdentifier);

        // Admin có thể xem tất cả; user chỉ xem order của mình
        if (context.User.IsInRole("Admin") || order.OwnerId == userId)
            context.Succeed(requirement);

        return Task.CompletedTask;
    }
}

// Sử dụng trong endpoint:
app.MapGet("/orders/{id}", async (
    string id,
    IAuthorizationService authz,
    ClaimsPrincipal user,
    IOrderRepository repo) =>
{
    var order = await repo.GetByIdAsync(id);
    if (order == null) return Results.NotFound();

    var result = await authz.AuthorizeAsync(user, order, new OrderOwnerRequirement());
    if (!result.Succeeded) return Results.Forbid();

    return Results.Ok(order);
});
```

### Task 6: Test claims và policies
```csharp
[Fact]
public async Task PremiumOnly_Allows_PremiumUser()
{
    var claims = new[] { new Claim("subscription_tier", "premium") };
    var user = new ClaimsPrincipal(new ClaimsIdentity(claims, "test"));

    var result = await _authService.AuthorizeAsync(user, null, "PremiumOnly");

    Assert.True(result.Succeeded);
}
```

## Expected Output
- `GET /premium-feature` với `subscription_tier: free` → 403
- `GET /premium-feature` với `subscription_tier: premium` → 200
- `PUT /orders/{id}` với token của userB cho order của userA → 403
- `PUT /orders/{id}` với Admin token → 200 (override)
- Claims transformation: thin JWT + DB lookup = full permissions

## Key Concepts
- **IUserClaimsPrincipalFactory**: add claims khi tạo token (Identity-only)
- **IClaimsTransformation**: enrich ClaimsPrincipal sau mỗi request authentication
- **Policy**: named set of requirements (cleaner than role checks)
- **IAuthorizationRequirement**: custom logic cho authorization
- **Resource-based**: pass resource object vào AuthorizeAsync (không chỉ dùng attribute)
- **Fat vs thin token**: fat = all claims in JWT; thin = minimal claims + enrich at runtime

## Resources
- [Policy-based authorization](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/policies)
- [Resource-based authorization](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/resourcebased)
- [IClaimsTransformation](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.authentication.iclaimstransformation)
