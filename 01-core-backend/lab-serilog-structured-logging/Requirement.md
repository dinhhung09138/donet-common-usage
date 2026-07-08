# Lab: Serilog Structured Logging

## Objectives
- Cài đặt Serilog trong ASP.NET Core với nhiều sinks
- Hiểu sự khác biệt giữa plain-text logs và structured logs
- Thêm enrichers để tự động bổ sung metadata vào mỗi log entry
- Cấu hình log level per namespace để kiểm soát verbosity
- Sử dụng destructuring để log complex objects dưới dạng structured data

## Prerequisites
- Lab: `lab-minimal-api` (cần ASP.NET Core project cơ bản)
- Docker Desktop (để chạy Seq)

## Tasks

### Task 1: Cài đặt Serilog
```bash
dotnet add package Serilog.AspNetCore
dotnet add package Serilog.Sinks.Console
dotnet add package Serilog.Sinks.File
dotnet add package Serilog.Sinks.Seq
dotnet add package Serilog.Enrichers.Environment
dotnet add package Serilog.Enrichers.Thread
```

Thay `builder.Logging` bằng Serilog trong `Program.cs`:
```csharp
builder.Host.UseSerilog((context, config) =>
    config.ReadFrom.Configuration(context.Configuration));
```

### Task 2: Cấu hình appsettings.json
```json
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft.AspNetCore": "Warning",
        "System": "Warning"
      }
    },
    "WriteTo": [
      { "Name": "Console", "Args": { "formatter": "Serilog.Formatting.Json.JsonFormatter, Serilog" } },
      { "Name": "File", "Args": { "path": "logs/log-.txt", "rollingInterval": "Day" } },
      { "Name": "Seq", "Args": { "serverUrl": "http://localhost:5341" } }
    ],
    "Enrich": ["FromLogContext", "WithMachineName", "WithThreadId", "WithEnvironmentName"]
  }
}
```

### Task 3: Destructuring với @ operator
```csharp
record OrderCreated(Guid Id, string CustomerId, decimal Amount);

app.MapPost("/orders", (OrderCreated order, ILogger<Program> logger) =>
{
    // Destructuring: lưu object properties riêng lẻ (searchable)
    logger.LogInformation("Order created {@Order}", order);

    // KHÔNG làm thế này — mất structure
    logger.LogInformation("Order created: " + order.ToString());

    return Results.Ok(order);
});
```

### Task 4: LogContext enrichment per request
```csharp
app.Use(async (context, next) =>
{
    using (LogContext.PushProperty("RequestPath", context.Request.Path))
    using (LogContext.PushProperty("UserId", context.User?.Identity?.Name ?? "anonymous"))
    {
        await next();
    }
});
```

### Task 5: Chạy Seq với Docker
```yaml
# docker-compose.yml
services:
  seq:
    image: datalust/seq:latest
    environment:
      - ACCEPT_EULA=Y
    ports:
      - "5341:5341"
      - "8080:80"
```

Chạy: `docker-compose up -d`  
Truy cập: http://localhost:8080

### Task 6: So sánh plain-text vs structured
Viết 2 log statements cho cùng một event:
```csharp
// Plain text — không searchable theo field
_logger.LogInformation($"User {userId} placed order {orderId} for {amount:C}");

// Structured — searchable, filterable trong Seq
_logger.LogInformation(
    "User {UserId} placed order {OrderId} for {Amount}",
    userId, orderId, amount);
```

Mở Seq UI, query: `UserId = '123'` — chỉ structured version mới searchable.

## Expected Output
- Console hiển thị JSON format (mỗi log entry là 1 JSON line)
- File `logs/log-YYYYMMDD.txt` được tạo tự động
- Seq UI tại http://localhost:8080 hiển thị logs với đầy đủ properties
- Query trong Seq: `Amount > 100` → filter đúng các orders

## Key Concepts
- **Sink**: nơi logs được ghi đến (Console, File, Seq, Application Insights, Elasticsearch)
- **Enricher**: tự động thêm properties vào mọi log entry (MachineName, ThreadId, etc.)
- **Destructuring (`@`)**: log object thành individual properties thay vì `.ToString()`
- **LogContext**: scoped properties tồn tại trong một block code
- **Minimum level override**: giảm verbosity của framework logs mà không ảnh hưởng app logs
- **Message template**: `"Hello {Name}"` — property name trong `{}` là key trong structured log

## Resources
- [Serilog official docs](https://serilog.net/)
- [Serilog.AspNetCore](https://github.com/serilog/serilog-aspnetcore)
- [Seq documentation](https://docs.datalust.co/docs)
- [Structured logging best practices](https://messagetemplates.org/)
