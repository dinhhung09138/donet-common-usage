# Lab: OAuth2 — Authorization Code + PKCE Flow

## Objectives
- Implement PKCE flow từ đầu để hiểu sâu cơ chế
- Generate `code_verifier` và `code_challenge` (S256)
- Validate `state` parameter để chống CSRF
- Demo 2 attack scenarios: code interception và CSRF
- Viết console app mô phỏng full flow

## Prerequisites
- Lab: `lab-identity-server-quickstart`

## Tasks

### Task 1: PKCE — tại sao cần thiết?
```
Vấn đề với Authorization Code (không có PKCE):
1. Client redirect đến /authorize → nhận code trong callback URL
2. Attacker có thể intercept code trong URL (logs, referrer header, shared machine)
3. Attacker dùng code để lấy token → impersonate user

PKCE giải quyết bằng cách:
1. Client tạo ngẫu nhiên code_verifier (43-128 chars)
2. Tính code_challenge = BASE64URL(SHA256(code_verifier))
3. Gửi code_challenge lên authorization server (không phải verifier)
4. Khi exchange code → phải gửi kèm code_verifier
5. Server verify: SHA256(verifier) == challenge
→ Attacker có code nhưng không có verifier → không thể exchange
```

### Task 2: Generate PKCE values
```csharp
public static class PkceHelper
{
    // code_verifier: 43-128 random URL-safe characters
    public static string GenerateCodeVerifier()
    {
        var bytes = new byte[32]; // 32 bytes → 43 chars base64url
        RandomNumberGenerator.Fill(bytes);
        return Base64UrlEncoder.Encode(bytes);
    }

    // code_challenge = BASE64URL(SHA256(ASCII(code_verifier)))
    public static string GenerateCodeChallenge(string codeVerifier)
    {
        var bytes = Encoding.ASCII.GetBytes(codeVerifier);
        var hash = SHA256.HashData(bytes);
        return Base64UrlEncoder.Encode(hash);
    }
}

// Usage:
var verifier = PkceHelper.GenerateCodeVerifier();
var challenge = PkceHelper.GenerateCodeChallenge(verifier);
Console.WriteLine($"verifier: {verifier}");
Console.WriteLine($"challenge: {challenge}");
```

### Task 3: Step 1 — Build Authorization URL
```csharp
public string BuildAuthorizationUrl(string verifier)
{
    var state = Base64UrlEncoder.Encode(RandomNumberGenerator.GetBytes(16));
    var challenge = PkceHelper.GenerateCodeChallenge(verifier);

    var parameters = new Dictionary<string, string>
    {
        ["response_type"] = "code",
        ["client_id"] = "orders-web",
        ["redirect_uri"] = "https://localhost:7001/callback",
        ["scope"] = "openid profile email orders:read",
        ["state"] = state,              // CSRF protection
        ["code_challenge"] = challenge,
        ["code_challenge_method"] = "S256"
    };

    var query = string.Join("&",
        parameters.Select(p => $"{p.Key}={Uri.EscapeDataString(p.Value)}"));

    return $"https://localhost:5001/connect/authorize?{query}";
}
```

### Task 4: Callback handler — validate state, extract code
```csharp
// GET /callback?code=xxx&state=yyy
app.MapGet("/callback", async (
    HttpContext ctx,
    string code,
    string state,
    ISessionStateService session) =>
{
    // Validate state (CSRF protection)
    var expectedState = session.Get("oauth_state");
    if (state != expectedState)
        return Results.BadRequest("Invalid state — possible CSRF attack");

    // Get stored verifier
    var verifier = session.Get("code_verifier");

    // Exchange code for tokens
    var tokens = await ExchangeCodeAsync(code, verifier!);
    return Results.Ok(tokens);
});
```

### Task 5: Step 2 — Exchange code for tokens
```csharp
public async Task<TokenResponse> ExchangeCodeAsync(string code, string verifier)
{
    var client = new HttpClient();
    var response = await client.PostAsync(
        "https://localhost:5001/connect/token",
        new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "authorization_code",
            ["client_id"] = "orders-web",
            ["client_secret"] = "web-secret",   // Confidential client
            ["code"] = code,
            ["redirect_uri"] = "https://localhost:7001/callback",
            ["code_verifier"] = verifier         // PKCE verifier
        }));

    var json = await response.Content.ReadFromJsonAsync<JsonElement>();
    return new TokenResponse
    {
        AccessToken = json.GetProperty("access_token").GetString()!,
        IdToken = json.GetProperty("id_token").GetString()!,
        RefreshToken = json.TryGetProperty("refresh_token", out var rt)
            ? rt.GetString() : null
    };
}
```

### Task 6: Demo Attack 1 — Code Interception (without PKCE)
```csharp
// Simulate: attacker intercepts authorization code
// Without PKCE: attacker can exchange code directly

// With PKCE: attacker has code but NOT verifier
// POST /connect/token with code + wrong verifier → 400 Bad Request
var attackResponse = await client.PostAsync(
    "https://localhost:5001/connect/token",
    new FormUrlEncodedContent(new Dictionary<string, string>
    {
        ["grant_type"] = "authorization_code",
        ["client_id"] = "orders-web",
        ["client_secret"] = "web-secret",
        ["code"] = interceptedCode,
        ["code_verifier"] = "random-wrong-verifier"  // attacker doesn't know real verifier
    }));

Assert.Equal(HttpStatusCode.BadRequest, attackResponse.StatusCode);
// Error: {"error": "invalid_grant", "error_description": "invalid code_verifier"}
```

### Task 7: Demo Attack 2 — CSRF (without state)
```csharp
// CSRF attack: trick user's browser into sending attacker's auth code to victim's callback
// Without state validation: victim's app accepts the code and links attacker's account

// With state: callback validates state from session
// Attacker doesn't know victim's session state → CSRF fails

// Test: send callback without state (or wrong state)
var csrfResponse = await client.GetAsync(
    "/callback?code=legit-code&state=attacker-state");

Assert.Equal(HttpStatusCode.BadRequest, csrfResponse.StatusCode);
// "Invalid state — possible CSRF attack"
```

## Expected Output
- Console app in ra URL đầy đủ với `code_challenge`
- Browser redirect → user login → callback với code
- Exchange code → access token
- Decode access token → verify claims
- Attack simulation 1: wrong verifier → 400 Bad Request
- Attack simulation 2: wrong state → 400 Bad Request

## Key Concepts
- **code_verifier**: random 43-128 char string, client keeps secret
- **code_challenge**: `BASE64URL(SHA256(verifier))`, sent in auth request
- **S256**: challenge method (always use S256, never "plain")
- **state**: round-trip CSRF token, must be random per request
- **PKCE**: Proof Key for Code Exchange — RFC 7636
- **Public vs Confidential client**: public (SPA, mobile) — must use PKCE; confidential (server) — should also use PKCE

## Resources
- [RFC 7636 — PKCE](https://www.rfc-editor.org/rfc/rfc7636)
- [OAuth 2.0 Security BCP](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [PKCE explained — Auth0](https://auth0.com/docs/get-started/authentication-and-authorization-flow/authorization-code-flow-with-pkce)
