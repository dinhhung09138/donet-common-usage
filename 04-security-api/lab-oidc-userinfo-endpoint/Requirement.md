# Lab: OIDC — ID Token, UserInfo Endpoint & Scopes

## Objectives
- Phân biệt ID Token và Access Token (mục đích, audience, lifetime)
- Gọi UserInfo endpoint để lấy thêm user claims
- Hiểu standard OIDC scopes và claims
- Map UserInfo response vào ClaimsPrincipal với ClaimActions
- Hiểu opaque vs JWT access token

## Prerequisites
- Lab: `lab-oidc-client-aspnetcore`
- Lab: `lab-identity-server-quickstart`

## Tasks

### Task 1: ID Token vs Access Token

```
ID Token:
- Mục đích: Authentication — "Who is this user?"
- Audience: Client application (ClientId)
- Claims: sub, iss, aud, iat, exp, nonce, email, name, ...
- Dùng để: Create session, display user info
- KHÔNG gửi đến Resource API

Access Token:
- Mục đích: Authorization — "What can this user do?"
- Audience: Resource API
- Claims: sub, scope, aud (API), iat, exp
- Dùng để: Gọi API (Bearer token)
- ID claims thường KHÔNG có trong access token

NEVER send ID Token to API — chỉ dùng Access Token
```

### Task 2: Decode và inspect ID Token
```csharp
// Middleware: log claims từ ID token sau khi validate
options.Events = new OpenIdConnectEvents
{
    OnTokenValidated = context =>
    {
        var idToken = context.SecurityToken as JwtSecurityToken;
        _logger.LogDebug("ID Token claims: {Claims}",
            idToken?.Claims.Select(c => $"{c.Type}={c.Value}"));

        // Standard ID token claims:
        // sub: user identifier (stable, opaque)
        // iss: issuer (IdentityServer URL)
        // aud: audience (your ClientId)
        // iat: issued at (Unix timestamp)
        // exp: expiration
        // nonce: matches value sent in auth request
        // at_hash: hash of access token (optional)

        return Task.CompletedTask;
    }
};
```

### Task 3: Standard OIDC Scopes và Claims

```
openid (required):
→ sub claim

profile:
→ name, given_name, family_name, middle_name
→ nickname, preferred_username, profile, picture, website
→ gender, birthdate, zoneinfo, locale, updated_at

email:
→ email, email_verified

phone:
→ phone_number, phone_number_verified

address:
→ address (JSON object: formatted, street_address, locality, region, postal_code, country)
```

```csharp
options.Scope.Clear();
options.Scope.Add("openid");
options.Scope.Add("profile");
options.Scope.Add("email");
options.Scope.Add("phone");
```

### Task 4: UserInfo endpoint
```
Thay vì đưa tất cả claims vào ID token (tăng size),
OIDC cho phép fetch thêm từ /userinfo endpoint bằng access token.

Khi nào dùng UserInfo:
✓ Claims không cần cho authorization (chỉ display)
✓ Claims có thể thay đổi (ví dụ: picture, address)
✓ Muốn ID token nhỏ gọn
```

```csharp
// Cấu hình:
options.GetClaimsFromUserInfoEndpoint = true;  // Tự động gọi /userinfo sau login

// Manual call (nếu cần refresh):
var handler = new JwtSecurityTokenHandler();
var accessToken = await HttpContext.GetTokenAsync("access_token");

var httpClient = new HttpClient();
httpClient.DefaultRequestHeaders.Authorization =
    new AuthenticationHeaderValue("Bearer", accessToken);

// Discover endpoint URL từ OpenID Configuration
var disco = await httpClient.GetFromJsonAsync<JsonElement>(
    "https://localhost:5001/.well-known/openid-configuration");
var userInfoEndpoint = disco.GetProperty("userinfo_endpoint").GetString();

var userInfo = await httpClient.GetFromJsonAsync<JsonElement>(userInfoEndpoint!);
// {"sub":"alice","name":"Alice Smith","email":"alice@example.com",...}
```

### Task 5: ClaimActions — map UserInfo vào ClaimsPrincipal
```csharp
options.ClaimActions.MapJsonKey("full_name", "name");
options.ClaimActions.MapJsonKey(ClaimTypes.Email, "email");
options.ClaimActions.MapJsonKey("given_name", "given_name");
options.ClaimActions.MapJsonKey("picture_url", "picture");

// Map phức tạp:
options.ClaimActions.MapCustomJson("display_name", json =>
    json.GetString("given_name") + " " + json.GetString("family_name"));

// Xóa claims không cần (giảm cookie size):
options.ClaimActions.DeleteClaim("nbf");
options.ClaimActions.DeleteClaim("amr");
```

### Task 6: Custom claims trong IdentityServer (server side)
```csharp
// IdentityServer — IProfileService để quyết định claims nào vào ID token vs UserInfo
public class CustomProfileService : IProfileService
{
    public Task GetProfileDataAsync(ProfileDataRequestContext context)
    {
        var user = context.Subject;

        // Luôn include trong ID token:
        context.IssuedClaims.Add(new Claim("sub", user.FindFirst("sub")!.Value));

        // Chỉ include trong UserInfo (không phải ID token):
        if (context.Caller == IdentityServerConstants.ProfileDataCallers.UserInfoEndpoint)
        {
            context.IssuedClaims.Add(new Claim("department", user.FindFirst("department")!.Value));
            context.IssuedClaims.Add(new Claim("employee_id", user.FindFirst("employee_id")!.Value));
        }

        return Task.CompletedTask;
    }

    public Task IsActiveAsync(IsActiveContext context)
    {
        context.IsActive = true;
        return Task.CompletedTask;
    }
}
```

### Task 7: Opaque vs JWT access token
```csharp
// IdentityServer: cấu hình access token type
new Client
{
    ClientId = "orders-web",
    AccessTokenType = AccessTokenType.Jwt,     // JWT — resource server tự validate
    // AccessTokenType = AccessTokenType.Reference  // Opaque — phải call introspection
    AccessTokenLifetime = 3600,  // 1 hour
    IdentityTokenLifetime = 300  // 5 minutes
}
```

## Expected Output
- Login → session có claims từ cả ID token và UserInfo endpoint
- `GET /me` → hiển thị đầy đủ profile (name, email, given_name, picture)
- ID token decode → thấy `sub`, `iss`, `aud`, `nonce`
- Access token decode → thấy `scope`, `aud` (API name)
- Phân biệt rõ: ID token audience = client, Access token audience = API

## Key Concepts
- **ID Token**: authentication artifact, audience = client app
- **Access Token**: authorization artifact, audience = resource API
- **UserInfo endpoint**: OAuth 2.0 protected endpoint, returns claims về authenticated user
- **Standard scopes**: openid, profile, email, phone, address
- **ClaimActions**: control which JSON fields from UserInfo become Claims
- **IProfileService**: IdentityServer hook để customize claims per request type

## Resources
- [OIDC Core Spec — UserInfo Endpoint](https://openid.net/specs/openid-connect-core-1_0.html#UserInfo)
- [Claims from UserInfo in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/social/additional-claims)
- [Duende IProfileService](https://docs.duendesoftware.com/identityserver/v7/fundamentals/claims/)
