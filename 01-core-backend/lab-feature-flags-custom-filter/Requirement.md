# Lab: Feature Flags — Custom IFeatureFilter

## Objectives
- Implement `IFeatureFilter` tùy chỉnh với business logic phức tạp
- Tạo TimeWindowFilter (chỉ bật trong khung giờ nhất định)
- Tạo ABTestFilter (random split dựa vào userId seed)
- Đọc typed parameters từ configuration trong filter
- Unit test custom filters với mocked context

## Prerequisites
- Lab: `lab-feature-flags-dotnet`
- Lab: `lab-feature-flags-targeting-filter`

## Tasks

### Task 1: TimeWindowFilter — flag chỉ bật trong giờ cao điểm
```csharp
[FilterAlias("TimeWindow")]
public class TimeWindowFilter : IFeatureFilter
{
    public Task<bool> EvaluateAsync(FeatureFilterEvaluationContext context)
    {
        var settings = context.Parameters.Get<TimeWindowSettings>();

        var now = TimeOnly.FromDateTime(DateTime.UtcNow);
        return Task.FromResult(now >= settings.Start && now <= settings.End);
    }
}

public class TimeWindowSettings
{
    public TimeOnly Start { get; set; }
    public TimeOnly End { get; set; }
}
```

Cấu hình:
```json
{
  "FeatureManagement": {
    "PeakHourPricing": {
      "EnabledFor": [
        {
          "Name": "TimeWindow",
          "Parameters": {
            "Start": "08:00:00",
            "End": "20:00:00"
          }
        }
      ]
    }
  }
}
```

### Task 2: BrowserVersionFilter — bật cho Chrome >= version X
```csharp
[FilterAlias("BrowserVersion")]
public class BrowserVersionFilter : IFeatureFilter
{
    private readonly IHttpContextAccessor _http;

    public Task<bool> EvaluateAsync(FeatureFilterEvaluationContext context)
    {
        var settings = context.Parameters.Get<BrowserVersionSettings>();
        var userAgent = _http.HttpContext?.Request.Headers["User-Agent"].ToString() ?? "";

        // Parse Chrome version từ User-Agent
        var match = Regex.Match(userAgent, @"Chrome/(\d+)");
        if (!match.Success) return Task.FromResult(false);

        var version = int.Parse(match.Groups[1].Value);
        return Task.FromResult(version >= settings.MinVersion);
    }
}

public class BrowserVersionSettings
{
    public int MinVersion { get; set; }
    public required string Browser { get; set; }
}
```

### Task 3: ABTestFilter — stable split dựa vào userId
```csharp
[FilterAlias("ABTest")]
public class ABTestFilter : IFeatureFilter
{
    private readonly IHttpContextAccessor _http;

    public Task<bool> EvaluateAsync(FeatureFilterEvaluationContext context)
    {
        var settings = context.Parameters.Get<ABTestSettings>();
        var userId = _http.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
                     ?? _http.HttpContext?.Connection.RemoteIpAddress?.ToString()
                     ?? "anonymous";

        // Stable hash: same userId always gets same group
        var hash = Math.Abs(HashCode.Combine(userId, context.FeatureName));
        var bucket = hash % 100;

        return Task.FromResult(bucket < settings.GroupAPercentage);
    }
}

public class ABTestSettings
{
    public int GroupAPercentage { get; set; } = 50;
}
```

### Task 4: Đăng ký tất cả custom filters
```csharp
builder.Services.AddFeatureManagement()
    .AddFeatureFilter<TimeWindowFilter>()
    .AddFeatureFilter<BrowserVersionFilter>()
    .AddFeatureFilter<ABTestFilter>();
```

### Task 5: Unit tests
```csharp
public class TimeWindowFilterTests
{
    [Theory]
    [InlineData("09:00", "08:00", "20:00", true)]
    [InlineData("22:00", "08:00", "20:00", false)]
    [InlineData("08:00", "08:00", "20:00", true)]  // boundary
    public async Task EvaluateAsync_ReturnsCorrectResult(
        string currentTime, string start, string end, bool expected)
    {
        // ... mock system clock, verify result
    }
}

public class ABTestFilterTests
{
    [Fact]
    public async Task SameUserId_AlwaysGetsConsistentGroup()
    {
        // Run 100 times — same userId → same result
        var userId = "user-123";
        var results = Enumerable.Range(0, 100)
            .Select(_ => EvaluateForUser(userId))
            .Distinct()
            .ToList();

        Assert.Single(results); // Only one unique result
    }
}
```

## Expected Output
- `PeakHourPricing` → enabled từ 8:00 đến 20:00 UTC, disabled ngoài giờ
- `NewUIComponents` → enabled chỉ với Chrome >= 120
- `CheckoutVariantA` → userA luôn trong group A, userB luôn trong group B
- Unit tests: 100% coverage cho mỗi filter với edge cases
- Thay đổi parameters trong appsettings → filter behavior thay đổi ngay

## Key Concepts
- **[FilterAlias("Name")]**: tên dùng trong `"Name": "TimeWindow"` config
- **FeatureFilterEvaluationContext**: context chứa tên feature + parameters
- **context.Parameters.Get<T>()**: bind configuration section vào typed settings object
- **Deterministic hashing**: `HashCode.Combine(userId, featureName)` đảm bảo stable split
- **IContextualFeatureFilter<TContext>**: filter nhận context được truyền tường minh từ caller

## Resources
- [Custom feature filter docs](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-feature-filters-aspnet-core)
- [FeatureFilterEvaluationContext API](https://learn.microsoft.com/en-us/dotnet/api/microsoft.featuremanagement.featurefilterationcontext)
- [A/B testing patterns](https://www.optimizely.com/optimization-glossary/ab-testing/)
