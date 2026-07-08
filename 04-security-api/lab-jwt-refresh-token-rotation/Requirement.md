# Lab: JWT Refresh Token Rotation & Token Theft Detection

## Objectives
- Implement access token (15 min) + refresh token (7 days) pair
- Rotation: invalidate old refresh token khi issue mới
- Token family: track related tokens, revoke tất cả nếu reuse detected
- Revoke all tokens khi user change password
- Hiểu tradeoff HttpOnly cookie vs localStorage

## Prerequisites
- Lab: `lab-aspnet-core-identity-setup`
- Lab: `lab-jwt-tokens-deep-dive`

## Tasks

### Task 1: RefreshToken entity và DbSet
```csharp
public class RefreshToken
{
    public Guid Id { get; set; }
    public required string UserId { get; set; }
    public required string TokenHash { get; set; }  // SHA-256 hash, không lưu raw
    public required string FamilyId { get; set; }   // Group of related tokens
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsRevoked { get; set; }
    public string? ReplacedByTokenId { get; set; }  // Audit chain

    public ApplicationUser User { get; set; } = null!;
}
```

### Task 2: Login — issue access token + refresh token pair
```csharp
app.MapPost("/auth/login", async (LoginRequest request, ...) =>
{
    var user = await AuthenticateUserAsync(request);
    if (user == null) return Results.Unauthorized();

    var familyId = Guid.NewGuid().ToString();  // Mới tạo family khi login

    var (accessToken, refreshToken) = await IssueTokenPairAsync(user, familyId);

    return Results.Ok(new TokenResponse
    {
        AccessToken = accessToken,
        AccessTokenExpiresIn = 900,  // 15 minutes
        RefreshToken = refreshToken,
        RefreshTokenExpiresIn = 604800  // 7 days
    });
});

async Task<(string access, string refresh)> IssueTokenPairAsync(
    ApplicationUser user, string familyId)
{
    var accessToken = jwtService.GenerateAccessToken(user);

    // Generate random refresh token
    var rawRefreshToken = RandomNumberGenerator.GetHexString(64);
    var hash = Convert.ToHexString(SHA256.HashData(
        Encoding.UTF8.GetBytes(rawRefreshToken)));

    await db.RefreshTokens.AddAsync(new RefreshToken
    {
        UserId = user.Id,
        TokenHash = hash,
        FamilyId = familyId,
        ExpiresAt = DateTime.UtcNow.AddDays(7)
    });
    await db.SaveChangesAsync();

    return (accessToken, rawRefreshToken);
}
```

### Task 3: Token refresh endpoint với rotation
```csharp
app.MapPost("/auth/token/refresh", async (RefreshRequest request, AppDbContext db, ...) =>
{
    var tokenHash = Convert.ToHexString(
        SHA256.HashData(Encoding.UTF8.GetBytes(request.RefreshToken)));

    var storedToken = await db.RefreshTokens
        .Include(t => t.User)
        .FirstOrDefaultAsync(t => t.TokenHash == tokenHash);

    // Token không tồn tại
    if (storedToken == null)
        return Results.Unauthorized();

    // REUSE DETECTION: Token đã bị revoke → có thể bị đánh cắp
    if (storedToken.IsRevoked)
    {
        // Revoke toàn bộ family (tất cả sessions của user này)
        await RevokeTokenFamilyAsync(storedToken.FamilyId, db);
        return Results.Problem("Refresh token reuse detected. All sessions revoked.",
            statusCode: 401);
    }

    // Token hết hạn
    if (storedToken.ExpiresAt < DateTime.UtcNow)
        return Results.Unauthorized();

    // Revoke token cũ
    storedToken.IsRevoked = true;

    // Issue token pair mới, giữ nguyên familyId
    var (newAccessToken, newRefreshToken) = await IssueTokenPairAsync(
        storedToken.User, storedToken.FamilyId);

    await db.SaveChangesAsync();

    return Results.Ok(new TokenResponse
    {
        AccessToken = newAccessToken,
        RefreshToken = newRefreshToken
    });
});
```

### Task 4: Token family revocation
```csharp
async Task RevokeTokenFamilyAsync(string familyId, AppDbContext db)
{
    var familyTokens = await db.RefreshTokens
        .Where(t => t.FamilyId == familyId && !t.IsRevoked)
        .ToListAsync();

    foreach (var token in familyTokens)
        token.IsRevoked = true;

    await db.SaveChangesAsync();
}
```

### Task 5: Revoke all tokens khi change password
```csharp
app.MapPost("/auth/change-password", async (ChangePasswordRequest request, ...) =>
{
    // Change password
    var result = await userManager.ChangePasswordAsync(user, request.OldPassword, request.NewPassword);
    if (!result.Succeeded) return Results.BadRequest(result.Errors);

    // Revoke ALL refresh tokens của user
    var userTokens = await db.RefreshTokens
        .Where(t => t.UserId == user.Id && !t.IsRevoked)
        .ToListAsync();

    foreach (var token in userTokens)
        token.IsRevoked = true;

    await db.SaveChangesAsync();

    return Results.Ok("Password changed. All sessions have been terminated.");
});
```

### Task 6: Cookie vs localStorage tradeoff
```
HttpOnly Cookie (recommended):
✓ JavaScript không đọc được → XSS-safe
✓ Tự động gửi trong mỗi request
✓ Secure flag → chỉ qua HTTPS
✓ SameSite=Strict → CSRF protection
✗ Không dùng được với cross-origin APIs

localStorage/sessionStorage:
✓ Easy cross-origin access
✓ Flexible cho SPAs
✗ XSS có thể đọc và đánh cắp token
✗ KHÔNG recommend cho sensitive data

Recommendation: 
- Access token: Authorization header (short-lived, dễ rotate)
- Refresh token: HttpOnly cookie + SameSite=Strict
```

### Task 7: Token theft scenario test
```csharp
[Fact]
public async Task RefreshToken_Reuse_RevokesEntireFamily()
{
    // 1. Login → get refresh token T1
    var loginResponse = await _client.PostAsJsonAsync("/auth/login", credentials);
    var tokens = await loginResponse.Content.ReadFromJsonAsync<TokenResponse>();

    // 2. Refresh → get T2, T1 is now revoked
    var refreshResponse = await RefreshAsync(tokens.RefreshToken);
    var newTokens = await refreshResponse.Content.ReadFromJsonAsync<TokenResponse>();

    // 3. Try to reuse T1 (simulates attacker using stolen token)
    var reuseResponse = await RefreshAsync(tokens.RefreshToken);

    // 4. T2 should also be revoked (entire family revoked)
    Assert.Equal(HttpStatusCode.Unauthorized, reuseResponse.StatusCode);
    var reuseT2Response = await RefreshAsync(newTokens.RefreshToken);
    Assert.Equal(HttpStatusCode.Unauthorized, reuseT2Response.StatusCode);
}
```

## Expected Output
- Login → access token (15 min) + refresh token (7 days)
- `/auth/token/refresh` → new pair, old token invalid
- Reuse old refresh token → 401, ALL family tokens revoked
- Change password → all refresh tokens revoked
- Unit test "token theft scenario" passes

## Key Concepts
- **Token rotation**: issue new refresh token on each use, invalidate old
- **Token family**: group of tokens from same login session
- **Reuse detection**: attacker uses old token → revoke whole family
- **Token hash**: store SHA-256 hash, not raw token (like password hashing)
- **Absolute expiry**: refresh token MUST expire even if used continuously
- **Silent refresh**: client proactively refresh access token before expiry

## Resources
- [Refresh token rotation - Auth0](https://auth0.com/docs/secure/tokens/refresh-tokens/refresh-token-rotation)
- [Token Best Practices - IETF RFC 6819](https://www.rfc-editor.org/rfc/rfc6819)
- [Where to store tokens](https://auth0.com/docs/secure/security-guidance/data-security/token-storage)
