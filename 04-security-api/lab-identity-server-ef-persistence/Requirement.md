# Lab: IdentityServer — EF Core Persistence

## Objectives
- Persist IdentityServer configuration vào SQL Server thay in-memory
- Persist operational data (tokens, grants, sessions) vào DB
- Viết seed script cho initial data
- Test multi-instance scenario (load balanced)
- Cấu hình token cleanup background service

## Prerequisites
- Lab: `lab-identity-server-quickstart`
- Lab: `lab-minimal-api` (EF Core migrations)

## Tasks

### Task 1: Cài đặt packages
```bash
dotnet add package Duende.IdentityServer.EntityFramework
dotnet add package Microsoft.EntityFrameworkCore.SqlServer
dotnet add package Microsoft.EntityFrameworkCore.Tools
```

### Task 2: Thay in-memory bằng EF stores
```csharp
// Program.cs — thay AddInMemory* bằng EF stores
builder.Services.AddIdentityServer()
    // ConfigurationStore: lưu Clients, Resources, Scopes
    .AddConfigurationStore(options =>
    {
        options.ConfigureDbContext = b => b.UseSqlServer(
            connectionString,
            sql => sql.MigrationsAssembly(typeof(Program).Assembly.FullName));
    })
    // OperationalStore: lưu tokens, grants, device codes, sessions
    .AddOperationalStore(options =>
    {
        options.ConfigureDbContext = b => b.UseSqlServer(
            connectionString,
            sql => sql.MigrationsAssembly(typeof(Program).Assembly.FullName));

        // Tự động cleanup expired tokens
        options.EnableTokenCleanup = true;
        options.TokenCleanupInterval = 3600; // giây
    })
    .AddDeveloperSigningCredential(); // Thay bằng cert trong production
```

### Task 3: Tạo migrations
```bash
# Tạo 2 migrations riêng — 1 cho mỗi DbContext
dotnet ef migrations add InitialIdentityServerConfigurationDbMigration \
    --context ConfigurationDbContext \
    --output-dir Migrations/ConfigurationDb

dotnet ef migrations add InitialIdentityServerPersistedGrantDbMigration \
    --context PersistedGrantDbContext \
    --output-dir Migrations/PersistedGrantDb

dotnet ef database update --context ConfigurationDbContext
dotnet ef database update --context PersistedGrantDbContext
```

Schema tạo ra:
- **ConfigurationDb**: `Clients`, `ClientScopes`, `ClientSecrets`, `ClientClaims`, `ApiResources`, `ApiResourceScopes`, `ApiScopes`, `IdentityResources`
- **PersistedGrantDb**: `PersistedGrants` (tokens), `DeviceCodes`, `Keys`, `ServerSideSessions`

### Task 4: Seed script — chạy khi startup
```csharp
public static class SeedData
{
    public static async Task EnsureSeedDataAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();

        // ConfigurationDb seed
        var configContext = scope.ServiceProvider.GetRequiredService<ConfigurationDbContext>();
        await configContext.Database.MigrateAsync();

        if (!configContext.Clients.Any())
        {
            foreach (var client in Config.Clients)
                configContext.Clients.Add(client.ToEntity());
            await configContext.SaveChangesAsync();
        }

        if (!configContext.IdentityResources.Any())
        {
            foreach (var resource in Config.IdentityResources)
                configContext.IdentityResources.Add(resource.ToEntity());
            await configContext.SaveChangesAsync();
        }

        if (!configContext.ApiScopes.Any())
        {
            foreach (var scope in Config.ApiScopes)
                configContext.ApiScopes.Add(scope.ToEntity());
            await configContext.SaveChangesAsync();
        }

        if (!configContext.ApiResources.Any())
        {
            foreach (var resource in Config.ApiResources)
                configContext.ApiResources.Add(resource.ToEntity());
            await configContext.SaveChangesAsync();
        }

        // PersistedGrantDb seed
        var grantContext = scope.ServiceProvider.GetRequiredService<PersistedGrantDbContext>();
        await grantContext.Database.MigrateAsync();
    }
}

// Program.cs:
await SeedData.EnsureSeedDataAsync(app.Services);
```

### Task 5: Thêm/sửa Client tại runtime
Sau khi có EF store, config clients bằng code hoặc admin UI:

```csharp
// Admin endpoint (protect với admin auth!)
app.MapPost("/admin/clients", async (
    ClientDto dto,
    ConfigurationDbContext db) =>
{
    var client = new Client
    {
        ClientId = dto.ClientId,
        AllowedGrantTypes = dto.GrantTypes,
        // ...
    };

    db.Clients.Add(client.ToEntity());
    await db.SaveChangesAsync();
    return Results.Created($"/admin/clients/{dto.ClientId}", null);
}).RequireAuthorization("Admin");
```

### Task 6: Multi-instance test
Chứng minh EF store hoạt động đúng khi chạy nhiều instances:

```yaml
# docker-compose.yml — 2 IdentityServer instances chia sẻ 1 SQL Server
services:
  identityserver-1:
    build: .
    ports: ["5001:5001"]
    environment:
      - ConnectionStrings__Default=Server=sqlserver;...
  
  identityserver-2:
    build: .
    ports: ["5002:5001"]
    environment:
      - ConnectionStrings__Default=Server=sqlserver;...  # SAME DB
  
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
```

Test:
1. Lấy token từ instance 1 (port 5001)
2. Dùng token đó gọi API → validate qua instance 2 (port 5002)
3. Token vẫn valid vì cả 2 share same signing key từ DB

### Task 7: Signing key rotation với automatic key management
```csharp
// Thay AddDeveloperSigningCredential():
builder.Services.AddIdentityServer()
    .AddConfigurationStore(...)
    .AddOperationalStore(...)
    // Automatic key management — lưu keys trong OperationalDb
    // Tự động rotate mỗi 90 ngày
    // KHÔNG dùng AddDeveloperSigningCredential trong production
```

Key rotation tự động:
- IdentityServer tạo RSA key mới mỗi 90 ngày
- Key cũ được giữ 14 ngày thêm để validate existing tokens
- Discovery document cập nhật JWKS ngay lập tức

## Expected Output
- `dotnet ef database update` chạy thành công cho cả 2 contexts
- IdentityServer restart → config còn nguyên (không mất khi restart)
- SQL Server: xem dữ liệu trong `Clients`, `ApiScopes` tables
- Multi-instance: token issue từ instance 1 validate được ở instance 2
- `PersistedGrants` table có entries sau khi login

## Key Concepts
- **ConfigurationDbContext**: lưu static config (clients, resources, scopes)
- **PersistedGrantDbContext**: lưu operational data (tokens, device codes, sessions)
- **ToEntity()**: extension method convert Duende model → EF entity
- **Token cleanup**: background service xóa expired tokens khỏi DB
- **Automatic Key Management**: Duende tự rotate signing keys, lưu trong OperationalDb
- **Multi-instance**: requires shared DB + shared signing keys

## Resources
- [Duende — EF Core integration](https://docs.duendesoftware.com/identityserver/v7/data/ef/)
- [Duende — operational data](https://docs.duendesoftware.com/identityserver/v7/data/operational/)
- [Duende — automatic key management](https://docs.duendesoftware.com/identityserver/v7/fundamentals/keys/)
