# Lab: Application Insights Telemetry

## Objectives
- Tích hợp Application Insights SDK vào ASP.NET Core
- Track custom events, metrics, và exceptions
- Hiểu automatic dependency tracking (HTTP, SQL, Service Bus)
- Tạo custom telemetry processor để filter/enrich data
- Sử dụng Live Metrics Stream khi load testing

## Prerequisites
- Azure subscription (free tier đủ)
- Lab: `lab-minimal-api`
- Lab: `lab-serilog-structured-logging` (hiểu logging concepts)

## Tasks

### Task 1: Cài đặt và cấu hình cơ bản
```bash
dotnet add package Microsoft.ApplicationInsights.AspNetCore
```

```csharp
// Program.cs
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
    options.EnableAdaptiveSampling = true;
});
```

```json
// appsettings.json
{
  "ApplicationInsights": {
    "ConnectionString": "InstrumentationKey=xxx;IngestionEndpoint=https://..."
  }
}
```

### Task 2: Track custom events
```csharp
public class OrderService
{
    private readonly TelemetryClient _telemetry;

    public async Task<Order> CreateOrderAsync(CreateOrderRequest request)
    {
        var order = await _repository.CreateAsync(request);

        // Custom event với properties
        _telemetry.TrackEvent("OrderCreated", new Dictionary<string, string>
        {
            ["OrderId"] = order.Id.ToString(),
            ["CustomerId"] = order.CustomerId,
            ["Channel"] = request.Channel
        },
        new Dictionary<string, double>
        {
            ["OrderAmount"] = (double)order.Amount,
            ["ItemCount"] = order.Items.Count
        });

        return order;
    }
}
```

### Task 3: Track custom metrics
```csharp
// Counter metric — tự động aggregate
_telemetry.GetMetric("OrdersProcessed").TrackValue(1);

// Multi-dimensional metric
var metric = _telemetry.GetMetric("PaymentProcessingTime", "PaymentProvider");
metric.TrackValue(stopwatch.ElapsedMilliseconds, "Stripe");
```

### Task 4: Custom exception telemetry
```csharp
try
{
    await ProcessPaymentAsync(order);
}
catch (PaymentException ex)
{
    _telemetry.TrackException(ex, new Dictionary<string, string>
    {
        ["OrderId"] = order.Id.ToString(),
        ["PaymentProvider"] = "Stripe",
        ["ErrorCode"] = ex.ErrorCode
    });
    throw;
}
```

### Task 5: Custom telemetry processor — filter health checks
```csharp
public class HealthCheckTelemetryFilter : ITelemetryProcessor
{
    private readonly ITelemetryProcessor _next;

    public HealthCheckTelemetryFilter(ITelemetryProcessor next) => _next = next;

    public void Process(ITelemetry item)
    {
        if (item is RequestTelemetry request &&
            request.Url?.AbsolutePath?.Contains("/health") == true)
        {
            return; // Drop health check requests — giảm noise
        }
        _next.Process(item);
    }
}

// Register:
builder.Services.AddApplicationInsightsTelemetryProcessor<HealthCheckTelemetryFilter>();
```

### Task 6: Correlation với Operation ID
```csharp
// App Insights tự động set Operation ID cho mỗi request
// Tất cả traces/dependencies/exceptions trong request share same Operation ID

// Manually track within same operation:
var operation = _telemetry.StartOperation<DependencyTelemetry>("ProcessInventory");
try
{
    await CheckInventoryAsync();
    operation.Telemetry.Success = true;
}
finally
{
    _telemetry.StopOperation(operation);
}
```

### Task 7: Xem dữ liệu trên Azure Portal
1. Application Insights → **Live Metrics** → chạy k6 load test → xem real-time
2. **Failures** → xem exceptions với full call stack
3. **Performance** → top slow operations, dependency failures
4. **Logs (KQL query)**:
```kusto
customEvents
| where name == "OrderCreated"
| summarize count() by bin(timestamp, 1h), tostring(customDimensions.Channel)
| render timechart
```

## Expected Output
- Application Insights nhận telemetry trong < 30 seconds sau khi deploy
- Custom events `OrderCreated` hiển thị trong Azure Portal
- SQL queries tự động tracked với duration (không cần manual code)
- Health check requests KHÔNG xuất hiện trong telemetry (filtered out)
- Live Metrics hiển thị request rate, failure rate khi load test

## Key Concepts
- **TelemetryClient**: main class để track telemetry manually
- **TrackEvent**: business events (không phải technical logs)
- **TrackMetric / GetMetric**: numeric measurements, auto-aggregated client-side
- **TrackDependency**: external calls (HTTP, DB, cache) — thường tự động
- **ITelemetryProcessor**: pipeline xử lý telemetry trước khi gửi
- **Adaptive sampling**: tự động giảm volume khi traffic cao để tiết kiệm cost
- **Operation ID**: correlate tất cả telemetry items trong 1 request

## Resources
- [Application Insights for ASP.NET Core](https://learn.microsoft.com/en-us/azure/azure-monitor/app/asp-net-core)
- [Custom events and metrics](https://learn.microsoft.com/en-us/azure/azure-monitor/app/api-custom-events-metrics)
- [Telemetry processors](https://learn.microsoft.com/en-us/azure/azure-monitor/app/api-filtering-sampling)
- [KQL query language](https://learn.microsoft.com/en-us/azure/data-explorer/kusto/query/)
