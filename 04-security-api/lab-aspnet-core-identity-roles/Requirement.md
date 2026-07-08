# Lab: ASP.NET Core Identity — Role Management

## Objectives
- Sử dụng RoleManager để CRUD roles
- Assign và revoke roles cho users
- Seed default roles và admin user khi startup
- Hiểu tradeoff role-based vs claims/policy-based authorization
- Implement admin user management API

## Prerequisites
- Lab: `lab-aspnet-core-identity-setup`

## Tasks

### Task 1: Đăng ký RoleManager
```csharp
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options => { ... })
    .AddEntityFrameworkStores<AppDbContext>()
    .AddRoles<IdentityRole>()  // Bật role support
    .AddDefaultTokenProviders();
```

### Task 2: Seed Roles và Admin user
```csharp
public static class IdentityDataSeeder
{
    public static readonly string[] DefaultRoles = ["Admin", "Manager", "User"];

    public static async Task SeedAsync(IServiceProvider services)
    {
        var roleManager = services.GetRequiredService<RoleManager<IdentityRole>>();
        var userManager = services.GetRequiredService<UserManager<ApplicationUser>>();

        // Seed roles
        foreach (var role in DefaultRoles)
        {
            if (!await roleManager.RoleExistsAsync(role))
                await roleManager.CreateAsync(new IdentityRole(role));
        }

        // Seed admin user
        const string adminEmail = "admin@example.com";
        if (await userManager.FindByEmailAsync(adminEmail) == null)
        {
            var admin = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                FullName = "System Admin",
                EmailConfirmed = true
            };

            await userManager.CreateAsync(admin, "Admin@123456!");
            await userManager.AddToRoleAsync(admin, "Admin");
        }
    }
}

// Gọi trong Program.cs:
using (var scope = app.Services.CreateScope())
{
    await IdentityDataSeeder.SeedAsync(scope.ServiceProvider);
}
```

### Task 3: Role management endpoints (Admin only)
```csharp
var adminApi = app.MapGroup("/api/admin").RequireAuthorization("AdminOnly");

// List all roles
adminApi.MapGet("/roles", async (RoleManager<IdentityRole> roleManager) =>
    Results.Ok(roleManager.Roles.Select(r => r.Name).ToList()));

// Create role
adminApi.MapPost("/roles", async (string roleName, RoleManager<IdentityRole> roleManager) =>
{
    if (await roleManager.RoleExistsAsync(roleName))
        return Results.Conflict("Role already exists");

    var result = await roleManager.CreateAsync(new IdentityRole(roleName));
    return result.Succeeded ? Results.Created("/api/admin/roles", roleName)
                            : Results.BadRequest(result.Errors);
});

// Assign role to user
adminApi.MapPost("/users/{userId}/roles/{roleName}", async (
    string userId, string roleName,
    UserManager<ApplicationUser> userManager) =>
{
    var user = await userManager.FindByIdAsync(userId);
    if (user == null) return Results.NotFound("User not found");

    if (!await userManager.IsInRoleAsync(user, roleName))
        await userManager.AddToRoleAsync(user, roleName);

    return Results.Ok();
});

// Get user with roles
adminApi.MapGet("/users/{userId}/roles", async (string userId,
    UserManager<ApplicationUser> userManager) =>
{
    var user = await userManager.FindByIdAsync(userId);
    if (user == null) return Results.NotFound();

    var roles = await userManager.GetRolesAsync(user);
    return Results.Ok(new { user.Email, user.FullName, Roles = roles });
});
```

### Task 4: Role-based endpoint protection
```csharp
// Option 1: Attribute
[Authorize(Roles = "Admin,Manager")]
[HttpGet("reports")]
public IActionResult GetReports() { ... }

// Option 2: Minimal API
app.MapGet("/reports", GetReports)
   .RequireAuthorization(policy => policy.RequireRole("Admin", "Manager"));

// Option 3: Policy (recommended — easier to test)
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("CanViewReports", policy => policy.RequireRole("Admin", "Manager"));
    options.AddPolicy("CanManageUsers", policy => policy.RequireRole("Admin"));
});
```

### Task 5: Include roles in JWT
```csharp
// Trong GenerateJwtToken — thêm role claims
var roles = await userManager.GetRolesAsync(user);
var claims = new List<Claim>
{
    new Claim(JwtRegisteredClaimNames.Sub, user.Id),
    new Claim(JwtRegisteredClaimNames.Email, user.Email!),
};

// Thêm mỗi role là 1 claim
claims.AddRange(roles.Select(r => new Claim(ClaimTypes.Role, r)));
```

JWT payload sẽ có:
```json
{
  "sub": "user-id",
  "email": "user@example.com",
  "role": ["Manager", "User"]
}
```

### Task 6: Role vs Claims/Policy — khi nào dùng cái nào?
```
Roles:
✓ Khi có số lượng roles nhỏ, cố định (Admin, Manager, User)
✓ Khi business logic đơn giản: "Admins can do X"
✗ KHÔNG nên dùng khi: permissions granular, nhiều roles, permission hay thay đổi

Claims/Policy:
✓ Khi cần granular permissions: "orders:write", "reports:export"
✓ Khi permissions dynamic (thay đổi mà không cần redeploy)
✓ Khi permission logic phức tạp: subscription tier + department + location
✓ Preferred cho production multi-tenant SaaS

Best practice: Roles cho RBAC đơn giản, combine với Claims cho fine-grained control
```

### Task 7: Unit tests
```csharp
[Fact]
public async Task GetReports_Returns403_ForUserRole()
{
    var client = _factory.CreateClientWithRole("User");
    var response = await client.GetAsync("/reports");
    Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
}

[Fact]
public async Task GetReports_Returns200_ForManagerRole()
{
    var client = _factory.CreateClientWithRole("Manager");
    var response = await client.GetAsync("/reports");
    Assert.Equal(HttpStatusCode.OK, response.StatusCode);
}
```

## Expected Output
- Seed chạy: roles Admin/Manager/User tồn tại, admin@example.com tồn tại
- `POST /api/admin/users/{id}/roles/Manager` → user được assign role
- `GET /reports` với Manager token → 200
- `GET /reports` với User token → 403
- Integration tests pass cho tất cả role scenarios

## Key Concepts
- **RoleManager<T>**: quản lý roles (CRUD, validate)
- **UserManager.AddToRoleAsync**: assign role, creates entry trong `AspNetUserRoles`
- **ClaimTypes.Role**: standard claim type cho roles trong JWT
- **RequireRole**: authorization shortcut, internally creates policy
- **Role seeding**: best practice chạy at startup, idempotent (check trước khi tạo)
- **Role claims**: thêm role permissions vào role entity (khác với user claims)

## Resources
- [Role-based authorization](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/roles)
- [RoleManager API](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.identity.rolemanager-1)
- [Claims vs Roles](https://learn.microsoft.com/en-us/aspnet/core/security/authorization/claimsbased)
