# Lab: OIDC Back-Channel Logout

## Objectives
- Implement back-channel logout endpoint nhận notification từ IdentityServer
- Validate `logout_token` (đặc biệt — khác access token)
- Revoke local session khi nhận logout notification
- So sánh front-channel vs back-channel logout
- Implement session management với check_session iframe

## Prerequisites
- Lab: `lab-oidc-client-aspnetcore`
- Lab: `lab-identity-server-ui-login`

## Tasks

### Task 1: Vấn đề với Front-Channel Logout
```
Front-Channel Logout:
- Browser load IdentityServer signout page
- IdentityServer embed hidden iframes cho mỗi client app
- Each iframe = GET request đến client's front-channel logout URL
- Browser xóa client's cookie

Vấn đề:
✗ Phụ thuộc vào browser (popup blockers, browser close)
✗ Không reliable nếu user đóng browser
✗ Không hoạt động khi browser không available (mobile, API clients)
✗ Security: CSRF risk

Back-Channel Logout:
- IdentityServer gửi POST request trực tiếp đến client's back-channel endpoint
- Server-to-server — không qua browser
- Reliable, không phụ thuộc vào browser
✓ Recommended cho production
```

### Task 2: Back-Channel Logout Endpoint
```csharp
// Client app (ví dụ: orders-web) implement endpoint
app.MapPost("/logout/backchannel", async (
    [FromForm] string logout_token,
    IBackChannelLogoutService logoutService) =>
{
    try
    {
        await logoutService.ProcessLogoutTokenAsync(logout_token);
        return Results.Ok();  // 200 = thành công
    }
    catch (SecurityTokenException ex)
    {
        return Results.BadRequest(new { error = "invalid_token", error_description = ex.Message });
    }
});

// Configure in Program.cs:
app.UseAuthentication();  // Must be before endpoint mapping
```

### Task 3: Validate Logout Token
```csharp
public class BackChannelLogoutService : IBackChannelLogoutService
{
    private readonly IOpenIdConnectConfigurationManager _configManager;
    private readonly ITicketStore _sessionStore;
    private readonly IOptions<OpenIdConnectOptions> _oidcOptions;

    public async Task ProcessLogoutTokenAsync(string logoutToken)
    {
        // Fetch signing keys từ IdentityServer
        var config = await _configManager.GetConfigurationAsync(CancellationToken.None);

        var handler = new JwtSecurityTokenHandler();
        var principal = handler.ValidateToken(logoutToken,
            new TokenValidationParameters
            {
                ValidIssuer = "https://localhost:5001",
                ValidAudience = "orders-web",  // ClientId
                IssuerSigningKeys = config.SigningKeys,
                ValidateLifetime = true,
            }, out var validatedToken);

        // Verify "events" claim (RFC 9278)
        var events = principal.FindFirstValue("events");
        if (!events?.Contains("http://schemas.openid.net/event/backchannel-logout") ?? true)
            throw new SecurityTokenException("Invalid logout token: missing events claim");

        // Verify NO "nonce" claim (logout token must not have nonce)
        if (principal.FindFirst("nonce") != null)
            throw new SecurityTokenException("Invalid logout token: nonce must not be present");

        // Get session ID to revoke
        var sid = principal.FindFirstValue("sid");
        var sub = principal.FindFirstValue("sub");

        await RevokeSessionAsync(sub, sid);
    }

    private async Task RevokeSessionAsync(string? sub, string? sid)
    {
        // Revoke user's session in your session store
        // Implementation depends on your session storage (DB, Redis, etc.)
        await _sessionStore.RevokeAsync(sub, sid);
    }
}
```

### Task 4: Session store với Redis
```csharp
// Đăng ký custom session store để có thể revoke sessions
builder.Services.AddAuthentication()
    .AddCookie(options =>
    {
        options.SessionStore = new RedisTicketStore(redisConnection);
    });

public class RedisTicketStore : ITicketStore
{
    private readonly IConnectionMultiplexer _redis;

    public async Task RevokeAsync(string? sub, string? sid)
    {
        if (sid != null)
        {
            // Xóa session theo SID
            await _redis.GetDatabase().KeyDeleteAsync($"session:{sid}");
        }
        else if (sub != null)
        {
            // Xóa tất cả sessions của user
            var keys = await GetAllSessionKeysForUser(sub);
            foreach (var key in keys)
                await _redis.GetDatabase().KeyDeleteAsync(key);
        }
    }
}
```

### Task 5: Cấu hình IdentityServer gửi back-channel logout
```csharp
// IdentityServer client config
new Client
{
    ClientId = "orders-web",
    BackChannelLogoutUri = "https://orders-app.example.com/logout/backchannel",
    BackChannelLogoutSessionRequired = true,  // Require SID in logout token
    // FrontChannelLogoutUri = "...",  // Có thể dùng cả hai
}
```

### Task 6: Front-Channel Logout (so sánh)
```csharp
// Client: đăng ký front-channel logout URL
options.SignedOutCallbackPath = "/signout-callback-oidc";

// IdentityServer:
new Client
{
    FrontChannelLogoutUri = "https://orders-app.example.com/signout-oidc",
    FrontChannelLogoutSessionRequired = true,
}

// Limitations — demo trong lab:
// 1. Gọi /signout từ client 1
// 2. IdentityServer load iframe cho client 2
// 3. Nếu browser block third-party iframes → client 2 KHÔNG logout
```

### Task 7: Check Session iframe (Session Management)
```csharp
// Polling approach: client periodically checks if session still valid
// (không cần back-channel logout nếu dùng cách này)
options.Events.OnTokenValidated = context =>
{
    // Lưu session state từ check_session_iframe response
    return Task.CompletedTask;
};

// JavaScript (trong Razor page):
// <iframe src="https://identityserver/.well-known/check_session" hidden></iframe>
// postMessage để check session state
```

## Expected Output
- Login với Client 1 và Client 2 (cùng IdentityServer)
- Logout từ Client 1 → IdentityServer gửi POST đến Client 2's back-channel URL
- Client 2 session revoked → user bị logout khi request tiếp theo
- Validate logout token: missing "events" claim → 400 Bad Request
- Logout token với "nonce" claim → rejected

## Key Concepts
- **Back-channel logout**: server-to-server notification, không qua browser
- **logout_token**: JWT đặc biệt — có `events` claim, không có `nonce`
- **SID (Session ID)**: identifies specific login session (không phải user)
- **ITicketStore**: ASP.NET Core interface để customize session storage
- **Front-channel vs back-channel**: browser-based vs server-to-server
- **RFC 9278**: Back-Channel Logout specification

## Resources
- [Back-Channel Logout Spec (RFC 9278)](https://www.rfc-editor.org/rfc/rfc9278)
- [Duende back-channel logout](https://docs.duendesoftware.com/identityserver/v7/ui/logout/notification/)
- [OIDC Session Management](https://openid.net/specs/openid-connect-session-1_0.html)
