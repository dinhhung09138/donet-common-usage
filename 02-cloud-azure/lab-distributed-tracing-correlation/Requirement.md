# Lab: Distributed Tracing — Correlation ID Pattern

## Objectives
- Implement Correlation ID middleware để track requests xuyên suốt services
- Gắn correlation ID vào tất cả log entries trong request scope
- Forward correlation ID khi gọi downstream services qua HttpClient
- Propagate correlation ID qua Azure Service Bus messages
- Demo end-to-end trace: API → Service Bus → Worker

## Prerequisites
- Lab: `lab-serilog-structured-logging`
- Lab: `lab-opentelemetry-tracing` (hiểu W3C traceparent)
- Lab: `lab-service-bus-patterns`

## Tasks

### Task 1: Correlation ID Middleware
```csharp
public class CorrelationIdMiddleware
{
    private const string Header = "X-Correlation-ID";
    private readonly RequestDelegate _next;

    public async Task InvokeAsync(HttpContext context)
    {
        // Lấy từ header nếu có (forwarded từ upstream), hoặc tạo mới
        var correlationId = context.Request.Headers[Header].FirstOrDefault()
                            ?? Guid.NewGuid().ToString("N")[..16].ToUpper();

        // Thêm vào response header
        context.Response.Headers[Header] = correlationId;

        // Đưa vào DI scope để các service khác dùng
        context.Items["CorrelationId"] = correlationId;

        // Thêm vào Serilog LogContext — mọi log trong request này đều có property này
        using (LogContext.PushProperty("CorrelationId", correlationId))
        {
            await _next(context);
        }
    }
}

// Register (phải đứng trước các middleware khác):
app.UseMiddleware<CorrelationIdMiddleware>();
```

### Task 2: ICorrelationIdProvider cho DI
```csharp
public interface ICorrelationIdProvider
{
    string Get();
}

public class HttpContextCorrelationIdProvider : ICorrelationIdProvider
{
    private readonly IHttpContextAccessor _accessor;

    public string Get()
        => _accessor.HttpContext?.Items["CorrelationId"]?.ToString()
           ?? "no-context";
}

// Register:
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICorrelationIdProvider, HttpContextCorrelationIdProvider>();
```

### Task 3: DelegatingHandler — forward khi gọi downstream
```csharp
public class CorrelationIdDelegatingHandler : DelegatingHandler
{
    private const string Header = "X-Correlation-ID";
    private readonly ICorrelationIdProvider _provider;

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request, CancellationToken cancellationToken)
    {
        request.Headers.TryAddWithoutValidation(Header, _provider.Get());
        return base.SendAsync(request, cancellationToken);
    }
}

// Register với typed HttpClient:
builder.Services.AddTransient<CorrelationIdDelegatingHandler>();
builder.Services.AddHttpClient<IInventoryClient, InventoryClient>()
    .AddHttpMessageHandler<CorrelationIdDelegatingHandler>();
```

### Task 4: Propagate qua Service Bus message
```csharp
// Publisher: thêm vào ApplicationProperties
public async Task PublishOrderCreatedAsync(Order order, string correlationId)
{
    var message = new ServiceBusMessage(JsonSerializer.Serialize(order))
    {
        CorrelationId = correlationId,  // Built-in property
        ApplicationProperties = { ["X-Correlation-ID"] = correlationId }
    };

    await _sender.SendMessageAsync(message);
}

// Consumer: đọc và đưa vào logging context
public async Task ProcessMessageAsync(ProcessMessageEventArgs args)
{
    var correlationId = args.Message.CorrelationId
                        ?? args.Message.ApplicationProperties
                                .GetValueOrDefault("X-Correlation-ID")?.ToString()
                        ?? "unknown";

    using (LogContext.PushProperty("CorrelationId", correlationId))
    {
        _logger.LogInformation("Processing order message");
        // ... process
    }
}
```

### Task 5: Demo end-to-end trace
```
Request → OrdersApi:
  X-Correlation-ID: ABC123XYZ789
  LOG: [ABC123XYZ789] Order received
  LOG: [ABC123XYZ789] Inventory check sent to InventoryService

InventoryService nhận request:
  Header: X-Correlation-ID: ABC123XYZ789 (forwarded)
  LOG: [ABC123XYZ789] Checking inventory for product P001

Service Bus message:
  CorrelationId: ABC123XYZ789
  
FulfillmentWorker nhận message:
  LOG: [ABC123XYZ789] Fulfillment started
  LOG: [ABC123XYZ789] Fulfillment completed
```

Search trong Seq: `CorrelationId = 'ABC123XYZ789'` → thấy tất cả logs từ mọi services.

### Task 6: AsyncLocal<T> cho non-HTTP context (Background services)
```csharp
public static class CorrelationContext
{
    private static readonly AsyncLocal<string?> _correlationId = new();

    public static string? Current
    {
        get => _correlationId.Value;
        set => _correlationId.Value = value;
    }
}

// Trong background service:
CorrelationContext.Current = Guid.NewGuid().ToString("N")[..16];
using (LogContext.PushProperty("CorrelationId", CorrelationContext.Current))
{
    await ProcessBatchAsync();
}
```

## Expected Output
- Mọi HTTP request có `X-Correlation-ID` header trong response
- Seq query `CorrelationId = 'ABC123'` → thấy logs từ API + InventoryService + Worker
- Service Bus messages có `CorrelationId` property
- Client gửi `X-Correlation-ID` → API tái sử dụng cùng ID (không tạo mới)

## Key Concepts
- **Correlation ID**: unique identifier gắn với một user request xuyên suốt hệ thống
- **LogContext.PushProperty**: Serilog scoped property — tự động reset khi ra khỏi `using`
- **DelegatingHandler**: HttpClient middleware pattern để inject headers
- **AsyncLocal<T>**: thread-safe storage theo async flow (không dùng static field)
- **Service Bus CorrelationId**: built-in property, khác với custom ApplicationProperties

## Resources
- [Correlation ID pattern](https://www.enterpriseintegrationpatterns.com/patterns/messaging/CorrelationIdentifier.html)
- [Serilog LogContext](https://github.com/serilog/serilog/wiki/Enrichment#the-logcontext)
- [HttpClient DelegatingHandler](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/http-requests#outgoing-request-middleware)
