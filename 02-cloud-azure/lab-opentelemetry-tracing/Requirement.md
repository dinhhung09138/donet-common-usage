# Lab: OpenTelemetry Distributed Tracing

## Objectives
- Cài đặt OpenTelemetry SDK trong ASP.NET Core
- Tạo custom spans với ActivitySource
- Propagate W3C traceparent header giữa 2 services
- Export traces sang Jaeger (local) và Application Insights (cloud)
- Hiểu sự khác biệt giữa OTel và Application Insights SDK

## Prerequisites
- Lab: `lab-minimal-api`
- Docker Desktop (để chạy Jaeger)

## Tasks

### Task 1: Cài đặt packages
```bash
dotnet add package OpenTelemetry.Extensions.Hosting
dotnet add package OpenTelemetry.Instrumentation.AspNetCore
dotnet add package OpenTelemetry.Instrumentation.Http
dotnet add package OpenTelemetry.Instrumentation.SqlClient
dotnet add package OpenTelemetry.Exporter.Jaeger
dotnet add package OpenTelemetry.Exporter.OpenTelemetryProtocol
dotnet add package Azure.Monitor.OpenTelemetry.AspNetCore
```

### Task 2: Cấu hình OpenTelemetry
```csharp
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService(
        serviceName: "OrdersApi",
        serviceVersion: "1.0.0"))
    .WithTracing(tracing => tracing
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSqlClientInstrumentation(o => o.SetDbStatementForText = true)
        .AddSource("OrdersApi.Business")  // Custom ActivitySource
        .AddJaegerExporter(o =>
        {
            o.AgentHost = "localhost";
            o.AgentPort = 6831;
        }))
    .WithMetrics(metrics => metrics
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddPrometheusExporter());
```

### Task 3: Custom ActivitySource và spans
```csharp
// Singleton ActivitySource — đặt ở class level
private static readonly ActivitySource ActivitySource = new("OrdersApi.Business");

public async Task<Order> ProcessOrderAsync(CreateOrderRequest request)
{
    // Start span — tự động trở thành child của HTTP span hiện tại
    using var activity = ActivitySource.StartActivity("ProcessOrder");

    // Thêm attributes (tags)
    activity?.SetTag("order.customer_id", request.CustomerId);
    activity?.SetTag("order.item_count", request.Items.Count);

    try
    {
        var inventory = await CheckInventoryAsync(request.Items);

        // Nested span
        using var paymentActivity = ActivitySource.StartActivity("ChargePayment");
        paymentActivity?.SetTag("payment.provider", "Stripe");
        var payment = await _paymentService.ChargeAsync(request.Total);
        paymentActivity?.SetTag("payment.transaction_id", payment.TransactionId);

        activity?.SetStatus(ActivityStatusCode.Ok);
        return await _repository.SaveAsync(order);
    }
    catch (Exception ex)
    {
        activity?.SetStatus(ActivityStatusCode.Error, ex.Message);
        activity?.RecordException(ex);
        throw;
    }
}
```

### Task 4: W3C traceparent propagation giữa 2 services
Tạo **2 projects**: `OrdersApi` (upstream) và `InventoryService` (downstream).

```csharp
// OrdersApi: gọi InventoryService — HttpClient tự động forward traceparent
var httpClient = httpClientFactory.CreateClient("InventoryService");
var response = await httpClient.GetAsync($"/inventory/{productId}");
// Header được set tự động: traceparent: 00-{traceId}-{spanId}-01
```

```csharp
// InventoryService: nhận request, span tự động là child của OrdersApi span
app.MapGet("/inventory/{productId}", async (string productId, ILogger<Program> logger) =>
{
    var traceId = Activity.Current?.TraceId.ToString();
    logger.LogInformation("Checking inventory for {ProductId}, TraceId: {TraceId}",
        productId, traceId);
    return Results.Ok(new { ProductId = productId, Available = true });
});
```

### Task 5: Jaeger với Docker
```yaml
# docker-compose.yml
services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "6831:6831/udp"  # Agent UDP
      - "16686:16686"    # UI
      - "14268:14268"    # HTTP collector
```

Chạy: `docker-compose up -d`  
Jaeger UI: http://localhost:16686

### Task 6: Export sang Application Insights
```csharp
// Thêm Azure Monitor exporter (dùng thay cho hoặc cùng Jaeger)
builder.Services.AddOpenTelemetry()
    .UseAzureMonitor(o =>
        o.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"]);
```

### Task 7: Baggage propagation
```csharp
// Set baggage ở upstream service
Activity.Current?.SetBaggage("tenant_id", tenantId);

// Đọc ở downstream service — tự động propagated
var tenantId = Activity.Current?.GetBaggageItem("tenant_id");
```

## Expected Output
- Jaeger UI tại http://localhost:16686 hiển thị traces
- 1 request tới OrdersApi → trace hiển thị spans: HTTP → ProcessOrder → CheckInventory → ChargePayment
- Distributed trace: OrdersApi → InventoryService share cùng `traceId`
- SQL queries xuất hiện là spans con trong trace
- `activity.RecordException` → exception details trong Jaeger

## Key Concepts
- **ActivitySource**: factory để tạo Activity (span) objects
- **Activity**: đại diện cho một span trong trace
- **W3C traceparent**: `00-{traceId}-{spanId}-{flags}` — tiêu chuẩn propagation header
- **Context propagation**: tự động qua HttpClient, manual qua Baggage
- **Instrumentation**: libraries tự động tạo spans (ASP.NET Core, HttpClient, SQL)
- **OTel vs App Insights SDK**: OTel là vendor-neutral, App Insights SDK lock-in Azure
- **OTLP**: OpenTelemetry Protocol — standard transport format

## Resources
- [OpenTelemetry .NET docs](https://opentelemetry.io/docs/instrumentation/net/)
- [W3C Trace Context spec](https://www.w3.org/TR/trace-context/)
- [Jaeger documentation](https://www.jaegertracing.io/docs/)
- [Azure Monitor OTel distro](https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable)
