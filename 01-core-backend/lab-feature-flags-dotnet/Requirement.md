# Lab: Feature Flags với Microsoft.FeatureManagement

## Objectives
- Sử dụng `Microsoft.FeatureManagement` để toggle features mà không cần redeploy
- Áp dụng feature flags ở controller, service, và Razor view
- Hiểu vòng đời của feature flag và cách quản lý trong production
- Kiểm tra feature flag bằng unit test

## Prerequisites
- Lab: `lab-minimal-api` (cần ASP.NET Core project)

## Tasks

### Task 1: Cài đặt packages
```bash
dotnet add package Microsoft.FeatureManagement.AspNetCore
```

Đăng ký trong `Program.cs`:
```csharp
builder.Services.AddFeatureManagement();
```

### Task 2: Định nghĩa flags trong appsettings.json
```json
{
  "FeatureManagement": {
    "NewCheckoutFlow": true,
    "BetaRecommendations": false,
    "DarkMode": true,
    "MaintenanceMode": false
  }
}
```

### Task 3: Sử dụng IFeatureManager trong service
```csharp
public class CheckoutService
{
    private readonly IFeatureManager _features;

    public CheckoutService(IFeatureManager features) => _features = features;

    public async Task<CheckoutResult> ProcessAsync(Cart cart)
    {
        if (await _features.IsEnabledAsync("NewCheckoutFlow"))
        {
            return await ProcessNewFlowAsync(cart);
        }
        return await ProcessLegacyFlowAsync(cart);
    }
}
```

### Task 4: [FeatureGate] attribute trên endpoint
```csharp
// Endpoint này trả 404 nếu flag tắt
app.MapGet("/api/recommendations", [FeatureGate("BetaRecommendations")] async () =>
{
    return Results.Ok(new[] { "Product A", "Product B" });
});

// Hoặc với Controllers:
[FeatureGate("BetaRecommendations")]
[HttpGet("recommendations")]
public IActionResult GetRecommendations() { ... }
```

### Task 5: Custom action khi feature disabled
```csharp
// Trả 503 thay vì 404 khi flag tắt
builder.Services.AddFeatureManagement()
    .UseDisabledFeaturesHandler(new RedirectDisabledFeatureHandler());

// Implement custom handler
public class RedirectDisabledFeatureHandler : IDisabledFeaturesHandler
{
    public Task HandleDisabledFeatures(IEnumerable<string> features, ActionExecutingContext context)
    {
        context.Result = new StatusCodeResult(503);
        return Task.CompletedTask;
    }
}
```

### Task 6: Feature flag trong Razor Tag Helper
```html
<!-- appsettings: "DarkMode": true -->
<feature name="DarkMode">
    <link rel="stylesheet" href="dark-theme.css" />
</feature>

<feature name="DarkMode" negate="true">
    <link rel="stylesheet" href="light-theme.css" />
</feature>
```

### Task 7: Unit test với mock IFeatureManager
```csharp
[Fact]
public async Task ProcessAsync_UsesNewFlow_WhenFlagEnabled()
{
    var featureManager = Substitute.For<IFeatureManager>();
    featureManager.IsEnabledAsync("NewCheckoutFlow").Returns(true);

    var service = new CheckoutService(featureManager);
    var result = await service.ProcessAsync(new Cart());

    Assert.IsType<NewFlowResult>(result);
}
```

## Expected Output
- `GET /api/checkout` → 200 với new flow khi flag bật, legacy flow khi tắt
- `GET /api/recommendations` → 404 khi `BetaRecommendations: false`
- Unit tests pass với cả 2 trạng thái flag
- Thay đổi flag trong `appsettings.json` → behavior thay đổi ngay (hot reload)

## Key Concepts
- **IFeatureManager**: interface chính để check feature flags
- **[FeatureGate]**: attribute decorator disable toàn bộ action/controller
- **IFeatureFilter**: interface để implement custom filter logic
- **IDisabledFeaturesHandler**: custom behavior khi feature bị tắt
- **Feature flag lifecycle**: dev → canary → rollout → retire
- **Decoupling**: separate deployment from release

## Resources
- [Microsoft.FeatureManagement docs](https://learn.microsoft.com/en-us/azure/azure-app-configuration/use-feature-flags-dotnet-core)
- [Feature Management GitHub](https://github.com/microsoft/FeatureManagement-Dotnet)
- [Feature Flags best practices](https://martinfowler.com/articles/feature-toggles.html)
