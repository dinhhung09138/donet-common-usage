# Lab: ASP.NET Core Identity — Setup & Registration Flow

## Objectives
- Scaffold EF-backed Identity với custom ApplicationUser
- Implement registration, login, email confirmation endpoints
- Cấu hình password complexity policy và account lockout
- Integrate JWT token generation với SignInManager
- Hiểu IdentityDbContext migrations và schema

## Prerequisites
- Lab: `lab-minimal-api` (EF Core cơ bản)
- SQL Server hoặc PostgreSQL

## Tasks

### Task 1: Cài đặt và scaffold
```bash
dotnet add package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
```

### Task 2: Custom ApplicationUser
```csharp
public class ApplicationUser : IdentityUser
{
    public required string FullName { get; set; }
    public string? TenantId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
}

public class AppDbContext : IdentityDbContext<ApplicationUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);  // PHẢI gọi base để tạo Identity tables
        // Custom configurations...
    }
}
```

### Task 3: Cấu hình Identity options
```csharp
builder.Services.AddIdentity<ApplicationUser, IdentityRole>(options =>
{
    // Password
    options.Password.RequiredLength = 8;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireDigit = true;

    // Lockout
    options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    options.Lockout.MaxFailedAccessAttempts = 5;
    options.Lockout.AllowedForNewUsers = true;

    // User
    options.User.RequireUniqueEmail = true;
    options.SignIn.RequireConfirmedEmail = false; // true trong production
})
.AddEntityFrameworkStores<AppDbContext>()
.AddDefaultTokenProviders();
```

### Task 4: Registration endpoint
```csharp
app.MapPost("/auth/register", async (
    RegisterRequest request,
    UserManager<ApplicationUser> userManager,
    IEmailSender emailSender) =>
{
    var user = new ApplicationUser
    {
        UserName = request.Email,
        Email = request.Email,
        FullName = request.FullName
    };

    var result = await userManager.CreateAsync(user, request.Password);

    if (!result.Succeeded)
        return Results.ValidationProblem(
            result.Errors.ToDictionary(e => e.Code, e => new[] { e.Description }));

    // Email confirmation
    var token = await userManager.GenerateEmailConfirmationTokenAsync(user);
    var confirmUrl = $"https://app.example.com/auth/confirm?userId={user.Id}&token={Uri.EscapeDataString(token)}";
    await emailSender.SendEmailAsync(user.Email!, "Confirm your email", confirmUrl);

    return Results.Ok(new { Message = "Registration successful. Please check your email." });
});
```

### Task 5: Login với JWT
```csharp
app.MapPost("/auth/login", async (
    LoginRequest request,
    UserManager<ApplicationUser> userManager,
    SignInManager<ApplicationUser> signInManager,
    IOptions<JwtSettings> jwtOptions) =>
{
    var user = await userManager.FindByEmailAsync(request.Email);
    if (user == null)
        return Results.Unauthorized();

    var result = await signInManager.CheckPasswordSignInAsync(user, request.Password,
        lockoutOnFailure: true);

    if (result.IsLockedOut)
        return Results.Problem("Account locked. Try again in 15 minutes.", statusCode: 423);

    if (!result.Succeeded)
        return Results.Unauthorized();

    var token = GenerateJwtToken(user, jwtOptions.Value);
    return Results.Ok(new { AccessToken = token, ExpiresIn = 3600 });
});

string GenerateJwtToken(ApplicationUser user, JwtSettings settings)
{
    var claims = new[]
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id),
        new Claim(JwtRegisteredClaimNames.Email, user.Email!),
        new Claim("full_name", user.FullName),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
    };

    var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SecretKey));
    var token = new JwtSecurityToken(
        issuer: settings.Issuer,
        audience: settings.Audience,
        claims: claims,
        expires: DateTime.UtcNow.AddHours(1),
        signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256));

    return new JwtSecurityTokenHandler().WriteToken(token);
}
```

### Task 6: UserManager operations
```csharp
// Tìm user
var user = await userManager.FindByIdAsync(userId);
var user = await userManager.FindByEmailAsync(email);

// Update profile
user.FullName = "New Name";
await userManager.UpdateAsync(user);

// Change password
await userManager.ChangePasswordAsync(user, oldPassword, newPassword);

// Reset password (forgot password flow)
var resetToken = await userManager.GeneratePasswordResetTokenAsync(user);
await userManager.ResetPasswordAsync(user, resetToken, newPassword);

// Check roles
var isAdmin = await userManager.IsInRoleAsync(user, "Admin");
```

### Task 7: Migration và seed
```bash
dotnet ef migrations add AddIdentity
dotnet ef database update
```

Identity schema tạo ra:
- `AspNetUsers` — users
- `AspNetRoles` — roles
- `AspNetUserRoles` — user-role mapping
- `AspNetUserClaims` — user claims
- `AspNetUserLogins` — external logins
- `AspNetUserTokens` — tokens (email confirm, password reset, 2FA)

## Expected Output
- `POST /auth/register` → 200 + email confirmation token in logs
- `POST /auth/login` → 200 + JWT, hoặc 401/423 (lockout)
- 5 failed login attempts → 423 Locked Out
- Email confirmation link validate thành công
- EF migrations run clean, all Identity tables created

## Key Concepts
- **UserManager<T>**: CRUD operations + validation trên IdentityUser
- **SignInManager<T>**: complex sign-in scenarios (lockout, 2FA, external login)
- **PasswordHasher**: bcrypt-like PBKDF2 hashing (không tự hash!)
- **LockoutOptions**: automatic brute force protection
- **ILookupNormalizer**: normalize email/username for case-insensitive lookup
- **DataProtectorTokenProvider**: generates email confirmation / password reset tokens

## Resources
- [Identity in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity)
- [UserManager API](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.identity.usermanager-1)
- [Identity EF Core](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-custom-storage-providers)
