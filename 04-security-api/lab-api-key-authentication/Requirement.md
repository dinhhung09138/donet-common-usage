# Lab: API Key Authentication

## Objectives
- Implement custom `AuthenticationHandler` cho API Key scheme
- Hash và store API keys an toàn (SHA-256 + salt)
- Key rotation với grace period (zero downtime)
- Per-key rate limiting và scope
- Audit logging: ai dùng key nào, khi nào

## Prerequisites
- Lab: `lab-aspnet-core-identity-setup`
- Lab: `lab-caching-patterns` (Redis)

## Tasks

### Task 1: ApiKey entity
```csharp
public class ApiKey
{
    public Guid Id { get; set; }
    public required string OwnerId { get; set; }       // User/Service account
    public required string KeyHash { get; set; }        // SHA-256(key + salt)
    public required string KeyPrefix { get; set; }      // First 8 chars (for lookup)
    public required string Salt { get; set; }           // Per-key salt
    public required string Name { get; set; }           // "Production API Key"
    public List<string> AllowedScopes { get; set; } = new();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ExpiresAt { get; set; }
    public bool IsRevoked { get; set; }
    public DateTime? LastUsedAt { get; set; }
    public string? RevokedReason { get; set; }
}
```

### Task 2: Key generation và storage
```csharp
public class ApiKeyService : IApiKeyService
{
    public (string rawKey, ApiKey entity) GenerateKey(string ownerId, string name,
        IEnumerable<string> scopes)
    {
        // Generate random key: "sk_live_" prefix + 32 random bytes
        var randomBytes = new byte[32];
        RandomNumberGenerator.Fill(randomBytes);
        var rawKey = "sk_live_" + Convert.ToHexString(randomBytes).ToLower();

        // Prefix: first 8 chars after "sk_live_" — used to find key in DB
        var prefix = rawKey[8..16];

        // Salt + Hash
        var salt = Convert.ToHexString(RandomNumberGenerator.GetBytes(16));
        var hash = HashKey(rawKey, salt);

        var entity = new ApiKey
        {
            OwnerId = ownerId,
            Name = name,
            KeyPrefix = prefix,
            KeyHash = hash,
            Salt = salt,
            AllowedScopes = scopes.ToList(),
            ExpiresAt = DateTime.UtcNow.AddYears(1)
        };

        // Return raw key ONCE — never stored, never retrievable
        return (rawKey, entity);
    }

    private static string HashKey(string rawKey, string salt)
    {
        var input = Encoding.UTF8.GetBytes(rawKey + salt);
        return Convert.ToHexString(SHA256.HashData(input));
    }
}
```

### Task 3: Custom AuthenticationHandler
```csharp
public class ApiKeyAuthenticationHandler : AuthenticationHandler<ApiKeyOptions>
{
    private const string ApiKeyHeader = "X-Api-Key";
    private readonly IApiKeyRepository _repository;
    private readonly IMemoryCache _cache;

    protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue(ApiKeyHeader, out var apiKeyValues))
            return AuthenticateResult.NoResult();  // Not this scheme's concern

        var providedKey = apiKeyValues.FirstOrDefault();
        if (string.IsNullOrEmpty(providedKey))
            return AuthenticateResult.Fail("API key is empty");

        // Validate format
        if (!providedKey.StartsWith("sk_live_") || providedKey.Length != 72)
            return AuthenticateResult.Fail("Invalid API key format");

        // Lookup by prefix (efficient — no full table scan)
        var prefix = providedKey[8..16];
        var cacheKey = $"apikey:{prefix}";

        var apiKey = await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5);
            return await _repository.FindByPrefixAsync(prefix);
        });

        if (apiKey == null)
            return AuthenticateResult.Fail("API key not found");

        if (apiKey.IsRevoked)
            return AuthenticateResult.Fail("API key has been revoked");

        if (apiKey.ExpiresAt.HasValue && apiKey.ExpiresAt < DateTime.UtcNow)
            return AuthenticateResult.Fail("API key has expired");

        // Verify hash
        var expectedHash = HashKey(providedKey, apiKey.Salt);
        if (!CryptographicOperations.FixedTimeEquals(
            Convert.FromHexString(expectedHash),
            Convert.FromHexString(apiKey.KeyHash)))
        {
            return AuthenticateResult.Fail("Invalid API key");
        }

        // Update last used (fire and forget)
        _ = _repository.UpdateLastUsedAsync(apiKey.Id);

        // Build claims
        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, apiKey.OwnerId),
            new Claim("api_key_id", apiKey.Id.ToString()),
            new Claim("api_key_name", apiKey.Name),
        }.Concat(apiKey.AllowedScopes.Select(s => new Claim("scope", s)));

        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, Scheme.Name);

        return AuthenticateResult.Success(ticket);
    }
}

// Register:
builder.Services.AddAuthentication()
    .AddScheme<ApiKeyOptions, ApiKeyAuthenticationHandler>("ApiKey", null);

// Options class:
public class ApiKeyOptions : AuthenticationSchemeOptions { }
```

### Task 4: Audit logging middleware
```csharp
app.Use(async (context, next) =>
{
    await next();

    // Log sau khi response đã được xử lý
    if (context.User.Identity?.AuthenticationType == "ApiKey")
    {
        var apiKeyId = context.User.FindFirstValue("api_key_id");
        var ownerId = context.User.FindFirstValue(ClaimTypes.NameIdentifier);

        _auditLogger.LogInformation(
            "API Key {ApiKeyId} (Owner: {OwnerId}) accessed {Method} {Path} → {StatusCode}",
            apiKeyId, ownerId,
            context.Request.Method, context.Request.Path,
            context.Response.StatusCode);
    }
});
```

### Task 5: Key rotation
```csharp
// Tạo key mới trước khi revoke key cũ (grace period)
app.MapPost("/api/keys/{keyId}/rotate", async (
    Guid keyId,
    IApiKeyService keyService,
    IApiKeyRepository repository,
    ClaimsPrincipal user) =>
{
    var ownerId = user.FindFirstValue(ClaimTypes.NameIdentifier)!;
    var existingKey = await repository.GetByIdAsync(keyId);
    if (existingKey == null || existingKey.OwnerId != ownerId)
        return Results.NotFound();

    // Create new key with same scopes
    var (rawNewKey, newEntity) = keyService.GenerateKey(
        ownerId, existingKey.Name + " (rotated)", existingKey.AllowedScopes);

    await repository.AddAsync(newEntity);

    // Schedule old key revocation (grace period: 24 hours)
    await _scheduler.ScheduleRevocationAsync(keyId, TimeSpan.FromHours(24),
        reason: $"Rotated, replaced by {newEntity.Id}");

    return Results.Ok(new
    {
        NewKey = rawNewKey,  // Show ONCE
        ExpiresAt = newEntity.ExpiresAt,
        OldKeyRevokesAt = DateTime.UtcNow.AddHours(24),
        Warning = "Save this key securely — it will not be shown again!"
    });
}).RequireAuthorization();
```

### Task 6: Scope-based authorization với API keys
```csharp
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("ApiKeyReadOrders", p =>
        p.AddAuthenticationSchemes("ApiKey", JwtBearerDefaults.AuthenticationScheme)
         .RequireClaim("scope", "orders:read"));
});

// Endpoint accepts BOTH JWT and API key:
app.MapGet("/orders", [Authorize("ApiKeyReadOrders")] async (IOrderRepository repo) =>
    Results.Ok(await repo.GetAllAsync()));
```

## Expected Output
- `POST /api/keys` → returns raw key once (sk_live_xxxxx...)
- `GET /orders` với `X-Api-Key: sk_live_xxxxx` → 200
- `GET /orders` với revoked key → 401
- `GET /orders` với wrong key → 401
- Audit log: mỗi request có ApiKeyId, OwnerId, path, status
- Key rotation: cả key cũ và mới hoạt động trong grace period

## Key Concepts
- **AuthenticationHandler**: custom authentication scheme trong ASP.NET Core pipeline
- **FixedTimeEquals**: constant-time comparison để chống timing attacks
- **Key prefix lookup**: tránh full table scan khi validate key
- **Salt per key**: mỗi key có salt riêng, ngăn rainbow table attacks
- **Grace period rotation**: tạo key mới → thông báo clients → revoke key cũ sau N giờ
- **NoResult vs Fail**: NoResult = scheme không nhận dạng; Fail = scheme nhận dạng nhưng invalid

## Resources
- [Custom AuthenticationHandler](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/customauth)
- [API Key best practices](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html)
- [Timing-safe comparison](https://learn.microsoft.com/en-us/dotnet/api/system.security.cryptography.cryptographicoperations.fixedtimeequals)
