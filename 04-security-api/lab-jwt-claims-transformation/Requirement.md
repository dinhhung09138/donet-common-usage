# Lab: JWT Claims Transformation — Thin Token + Runtime Enrichment

## Objectives
- Hiểu "fat token" vs "thin token" và khi nào dùng cái nào
- Implement `IClaimsTransformation` load permissions từ DB/Redis
- Cache claims per user để tránh DB query mỗi request
- Invalidate cache khi permissions thay đổi
- So sánh: embed permissions in JWT vs lookup at runtime

## Prerequisites
- Lab: `lab-jwt-tokens-deep-dive`
- Lab: `lab-caching-patterns` (Redis IDistributedCache)

## Tasks

### Task 1: Vấn đề với Fat Token
```
Fat Token (tất cả claims trong JWT):
✓ Stateless — không cần DB lookup
✓ Performance cao
✗ Token lớn → network overhead mỗi request
✗ Stale permissions: nếu revoke permission, phải đợi token expire
✗ Không thể revoke ngay lập tức
✗ Sensitive data exposed trong payload (decodable by anyone)

Thin Token (minimal claims):
✓ Token nhỏ (chỉ sub, iat, exp)
✓ Permissions luôn fresh (load từ DB)
✓ Revoke ngay lập tức (chỉ xóa từ DB)
✗ DB lookup mỗi request (giải quyết bằng cache)
✗ Phụ thuộc vào availability của permission store

Khi nào dùng Thin Token:
✓ Permissions thay đổi thường xuyên
✓ Cần revoke ngay (security incident, terminated employee)
✓ Multi-tenant với dynamic permissions
```

### Task 2: Thin JWT — chỉ essential claims
```csharp
// Auth server chỉ đưa tối thiểu vào JWT
public string GenerateAccessToken(ApplicationUser user)
{
    var claims = new[]
    {
        new Claim(JwtRegisteredClaimNames.Sub, user.Id),
        new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
        // KHÔNG đưa roles, permissions vào đây
    };

    // Short expiry (15 min) — permissions luôn fresh
    return CreateToken(claims, TimeSpan.FromMinutes(15));
}
```

### Task 3: IClaimsTransformation với Redis cache
```csharp
public class PermissionsClaimsTransformation : IClaimsTransformation
{
    private readonly IPermissionRepository _permRepo;
    private readonly IDistributedCache _cache;
    private readonly ILogger<PermissionsClaimsTransformation> _logger;

    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        // Chỉ process authenticated users
        if (!principal.Identity?.IsAuthenticated ?? true)
            return principal;

        var userId = principal.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (userId == null) return principal;

        var permissions = await GetCachedPermissionsAsync(userId);

        // Tạo new identity với enriched claims
        var enrichedIdentity = new ClaimsIdentity();
        enrichedIdentity.AddClaims(
            permissions.Select(p => new Claim("permission", p)));

        // Role từ DB (không từ JWT)
        var roles = await GetCachedRolesAsync(userId);
        enrichedIdentity.AddClaims(
            roles.Select(r => new Claim(ClaimTypes.Role, r)));

        principal.AddIdentity(enrichedIdentity);
        return principal;
    }

    private async Task<IEnumerable<string>> GetCachedPermissionsAsync(string userId)
    {
        var cacheKey = $"permissions:v1:{userId}";

        var cached = await _cache.GetStringAsync(cacheKey);
        if (cached != null)
        {
            _logger.LogDebug("Permissions cache hit for user {UserId}", userId);
            return JsonSerializer.Deserialize<string[]>(cached)!;
        }

        _logger.LogDebug("Permissions cache miss for user {UserId}", userId);
        var permissions = await _permRepo.GetPermissionsAsync(userId);
        var serialized = JsonSerializer.Serialize(permissions.ToArray());

        await _cache.SetStringAsync(cacheKey, serialized,
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
            });

        return permissions;
    }
}

// Register:
builder.Services.AddScoped<IClaimsTransformation, PermissionsClaimsTransformation>();
```

### Task 4: Cache invalidation khi permissions thay đổi
```csharp
public class PermissionService : IPermissionService
{
    private readonly IDistributedCache _cache;

    public async Task GrantPermissionAsync(string userId, string permission)
    {
        await _repository.AddPermissionAsync(userId, permission);

        // Invalidate cache — next request sẽ load fresh từ DB
        await _cache.RemoveAsync($"permissions:v1:{userId}");
        await _cache.RemoveAsync($"roles:v1:{userId}");
    }

    public async Task RevokePermissionAsync(string userId, string permission)
    {
        await _repository.RemovePermissionAsync(userId, permission);
        await _cache.RemoveAsync($"permissions:v1:{userId}");
    }
}
```

### Task 5: Cache versioning (invalidate tất cả nếu cần)
```csharp
// Khi schema thay đổi, bump version trong key
private const string CacheVersion = "v2";  // đổi từ v1 → v2 = invalidate tất cả

var cacheKey = $"permissions:{CacheVersion}:{userId}";
```

### Task 6: Đọc current user trong service
```csharp
public class OrderService
{
    private readonly IHttpContextAccessor _accessor;

    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        var userId = _accessor.HttpContext?.User
            .FindFirstValue(JwtRegisteredClaimNames.Sub);

        var hasPermission = _accessor.HttpContext?.User
            .HasClaim("permission", "orders:write") ?? false;

        if (!hasPermission)
            throw new ForbiddenException("Missing permission: orders:write");

        // ... create order
    }
}
```

### Task 7: Test cache behavior
```csharp
[Fact]
public async Task Permission_UpdatedInDB_ReflectedWithinCacheTTL()
{
    // Grant permission
    await _permService.GrantPermissionAsync(userId, "reports:export");

    // First request — should hit DB
    var response1 = await _client.GetAsync("/export");
    Assert.Equal(HttpStatusCode.OK, response1.StatusCode);

    // Revoke permission
    await _permService.RevokePermissionAsync(userId, "reports:export");

    // Cache invalidated → next request hits DB → 403
    var response2 = await _client.GetAsync("/export");
    Assert.Equal(HttpStatusCode.Forbidden, response2.StatusCode);
}
```

## Expected Output
- JWT chỉ có `sub` + `jti` + `iat` + `exp`
- Sau transformation: ClaimsPrincipal có đầy đủ permissions + roles
- Revoke permission → cache invalidated → API returns 403 ngay lập tức
- Cache hit → log "Permissions cache hit", no DB query
- 1000 concurrent requests → permissions loaded once per user per 5 min

## Key Concepts
- **IClaimsTransformation**: ASP.NET Core hook sau authentication, trước authorization
- **Thin token**: chỉ identity in JWT, permissions loaded at runtime
- **Cache key namespacing**: `permissions:v1:{userId}` — version cho easy bulk invalidation
- **ClaimsIdentity aggregation**: principal có thể có nhiều identities
- **IHttpContextAccessor**: inject HttpContext vào services (cẩn thận với background services)
- **Cache TTL tradeoff**: ngắn = fresh data, dài = fewer DB queries

## Resources
- [IClaimsTransformation docs](https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.authentication.iclaimstransformation)
- [Claims principal](https://learn.microsoft.com/en-us/dotnet/api/system.security.claims.claimsprincipal)
- [Distributed caching in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/performance/caching/distributed)
