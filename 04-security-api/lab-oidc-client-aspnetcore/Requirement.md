# Lab: OpenID Connect Client trong ASP.NET Core

## Objectives
- Cài đặt OIDC login flow trong ASP.NET Core web app
- Hiểu authorization code flow với PKCE end-to-end
- Quản lý session sau callback (cookie-based)
- Lưu và sử dụng access token trong controller
- Xử lý token renewal (silent refresh)

## Prerequisites
- Lab: `lab-identity-server-quickstart` (cần OIDC provider)
- Kiến thức HTTP redirects và cookies

## Tasks

### Task 1: Cài đặt Authentication
```bash
dotnet add package Microsoft.AspNetCore.Authentication.OpenIdConnect
dotnet add package Microsoft.AspNetCore.Authentication.Cookies
```

```csharp
builder.Services.AddAuthentication(options =>
{
    options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
})
.AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
{
    options.ExpireTimeSpan = TimeSpan.FromHours(8);
    options.SlidingExpiration = true;
})
.AddOpenIdConnect(OpenIdConnectDefaults.AuthenticationScheme, options =>
{
    options.Authority = "https://localhost:5001";  // IdentityServer
    options.ClientId = "orders-web";
    options.ClientSecret = "secret";
    options.ResponseType = "code";  // Authorization code

    // PKCE (required for public clients, recommended for confidential)
    options.UsePkce = true;

    // Scopes
    options.Scope.Clear();
    options.Scope.Add("openid");
    options.Scope.Add("profile");
    options.Scope.Add("email");
    options.Scope.Add("orders-api");  // Custom API scope

    // Save tokens trong cookie để dùng sau
    options.SaveTokens = true;

    options.GetClaimsFromUserInfoEndpoint = true;

    options.CallbackPath = "/signin-oidc";  // Must match redirect_uri in IdentityServer
    options.SignedOutCallbackPath = "/signout-callback-oidc";
});
```

### Task 2: Protect routes
```csharp
app.UseAuthentication();
app.UseAuthorization();

// Yêu cầu login cho toàn bộ app
app.MapDefaultControllerRoute()
   .RequireAuthorization();

// Hoặc exempt public pages:
app.MapGet("/", () => "Welcome!").AllowAnonymous();
app.MapGet("/dashboard", [Authorize] () => "Secret Dashboard");
```

### Task 3: Login/Logout actions
```csharp
app.MapGet("/login", () =>
    Results.Challenge(new AuthenticationProperties
    {
        RedirectUri = "/dashboard",
        IsPersistent = true  // "Remember me"
    }, new[] { OpenIdConnectDefaults.AuthenticationScheme }));

app.MapGet("/logout", async (HttpContext ctx) =>
{
    await ctx.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
    await ctx.SignOutAsync(OpenIdConnectDefaults.AuthenticationScheme,
        new AuthenticationProperties { RedirectUri = "/" });
});
```

### Task 4: Sử dụng access token trong controller
```csharp
[Authorize]
public class OrdersController : Controller
{
    private readonly IHttpClientFactory _httpClientFactory;

    public async Task<IActionResult> Index()
    {
        // Lấy access token từ cookie (đã được lưu bởi SaveTokens = true)
        var accessToken = await HttpContext.GetTokenAsync("access_token");
        var refreshToken = await HttpContext.GetTokenAsync("refresh_token");

        var client = _httpClientFactory.CreateClient("OrdersApi");
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", accessToken);

        var orders = await client.GetFromJsonAsync<List<Order>>("/api/orders");
        return View(orders);
    }
}
```

### Task 5: Đọc user claims
```csharp
[Authorize]
app.MapGet("/me", (ClaimsPrincipal user) =>
{
    return Results.Ok(new
    {
        UserId = user.FindFirstValue("sub"),
        Email = user.FindFirstValue("email"),
        Name = user.FindFirstValue("name"),
        // Claims từ UserInfo endpoint (nếu GetClaimsFromUserInfoEndpoint = true)
        GivenName = user.FindFirstValue("given_name"),
        FamilyName = user.FindFirstValue("family_name"),
        AllClaims = user.Claims.Select(c => new { c.Type, c.Value }).ToList()
    });
});
```

### Task 6: State parameter và nonce
OIDC middleware tự động:
- **state**: random value để verify redirect không bị tampered (CSRF protection)
- **nonce**: random value được embed trong ID token, verify token freshness
- **PKCE**: code_verifier / code_challenge

```csharp
// Customize state (VD: save return URL)
options.Events = new OpenIdConnectEvents
{
    OnRedirectToIdentityProvider = context =>
    {
        // Thêm custom params vào authorization request
        context.ProtocolMessage.SetParameter("ui_locales", "vi");
        return Task.CompletedTask;
    },

    OnTokenValidated = context =>
    {
        // Validate thêm sau khi token valid
        var email = context.Principal?.FindFirstValue("email");
        if (!email?.EndsWith("@company.com") ?? true)
        {
            context.Fail("Only company email allowed");
        }
        return Task.CompletedTask;
    }
};
```

### Task 7: Silent token renewal
```csharp
// Khi access token expire, dùng refresh token để lấy mới
options.Events = new OpenIdConnectEvents
{
    OnTokenValidated = context =>
    {
        // Lưu expiry vào cookie
        context.Properties.UpdateTokenValue("expires_at",
            DateTime.UtcNow.AddSeconds(3600).ToString("O"));
        return Task.CompletedTask;
    }
};

// Middleware kiểm tra và refresh token trước mỗi request
app.Use(async (context, next) =>
{
    var expiresAt = context.User.FindFirstValue("expires_at");
    if (DateTime.TryParse(expiresAt, out var expiry) && expiry < DateTime.UtcNow.AddMinutes(5))
    {
        // Token gần hết hạn → refresh
        await context.ChallengeAsync(OpenIdConnectDefaults.AuthenticationScheme,
            new AuthenticationProperties { RedirectUri = context.Request.Path });
        return;
    }
    await next();
});
```

## Expected Output
- Truy cập `/dashboard` → redirect đến IdentityServer login page
- Login thành công → redirect về `/dashboard` với cookie session
- `GET /me` → trả claims của user
- `GET /orders` → gọi API với Bearer token, hiển thị orders
- Logout → redirect đến IdentityServer signout, cookie xóa

## Key Concepts
- **Authorization Code flow**: browser redirect → code → exchange for tokens
- **PKCE**: Proof Key for Code Exchange — bảo vệ code từ interception
- **nonce**: one-time value trong ID token, verify token không bị reused
- **SaveTokens**: lưu access/refresh/id token trong authentication cookie
- **GetClaimsFromUserInfoEndpoint**: fetch thêm claims từ `/userinfo` endpoint
- **state**: round-trip value, verify redirect không bị CSRF

## Resources
- [OIDC in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/social/additional-claims)
- [OpenID Connect spec](https://openid.net/specs/openid-connect-core-1_0.html)
- [Cookie + OIDC pattern](https://docs.duendesoftware.com/identityserver/v7/quickstarts/2_interactive/)
