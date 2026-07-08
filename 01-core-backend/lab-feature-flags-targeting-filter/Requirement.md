# Lab: Feature Flags — Targeting Filter & Percentage Rollout

## Objectives
- Bật feature flag cho user/group cụ thể bằng TargetingFilter
- Implement ITargetingContextAccessor để cung cấp user context
- Cấu hình percentage rollout (canary release)
- Viết test kiểm tra targeting logic

## Prerequisites
- Lab: `lab-feature-flags-dotnet` (cần IFeatureManager cơ bản)
- Lab: `lab-aspnet-core-identity-setup` (cần authenticated users)

## Tasks

### Task 1: Cài packages và đăng ký TargetingFilter
```bash
dotnet add package Microsoft.FeatureManagement.AspNetCore
```

```csharp
builder.Services.AddFeatureManagement()
    .WithTargeting<AppTargetingContextAccessor>();
```

### Task 2: Implement ITargetingContextAccessor
```csharp
public class AppTargetingContextAccessor : ITargetingContextAccessor
{
    private readonly IHttpContextAccessor _httpContext;

    public AppTargetingContextAccessor(IHttpContextAccessor httpContext)
        => _httpContext = httpContext;

    public ValueTask<TargetingContext> GetContextAsync()
    {
        var user = _httpContext.HttpContext?.User;

        return ValueTask.FromResult(new TargetingContext
        {
            UserId = user?.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "anonymous",
            Groups = user?.FindAll("subscription")
                        .Select(c => c.Value)
                        .ToList() ?? new List<string>()
        });
    }
}
```

### Task 3: Cấu hình Targeting trong appsettings.json
```json
{
  "FeatureManagement": {
    "BetaDashboard": {
      "EnabledFor": [
        {
          "Name": "Targeting",
          "Parameters": {
            "Audience": {
              "Users": ["alice@example.com", "bob@example.com"],
              "Groups": [
                { "Name": "beta-testers", "RolloutPercentage": 100 },
                { "Name": "premium", "RolloutPercentage": 50 }
              ],
              "DefaultRolloutPercentage": 10
            }
          }
        }
      ]
    }
  }
}
```

### Task 4: Percentage rollout stages
Mô phỏng canary release — thay đổi `DefaultRolloutPercentage`:
```
Stage 1: 5%   → monitor errors/latency
Stage 2: 25%  → check business metrics
Stage 3: 50%  → broader rollout
Stage 4: 100% → full release → remove flag
```

### Task 5: Exclude list (opt-out)
```json
{
  "Audience": {
    "Exclusion": {
      "Users": ["testuser@example.com"],
      "Groups": ["internal-qa"]
    },
    "DefaultRolloutPercentage": 30
  }
}
```

### Task 6: Unit test targeting logic
```csharp
[Theory]
[InlineData("alice@example.com", "beta-testers", true)]   // user trong Users list
[InlineData("unknown@example.com", "premium", true)]       // group premium 50%... có thể pass
[InlineData("excluded@example.com", "internal-qa", false)] // excluded
public async Task BetaDashboard_RespectsTargeting(string userId, string group, bool expected)
{
    var context = new TargetingContext
    {
        UserId = userId,
        Groups = new[] { group }
    };

    var evaluator = new TargetingEvaluator(Options.Create(new TargetingEvaluationOptions()));
    // ...test targeting logic
}
```

## Expected Output
- `alice@example.com` → feature enabled (trong Users list)
- `regular@example.com` → ~10% chance enabled (DefaultRolloutPercentage)
- `excluded@example.com` → always disabled (Exclusion)
- `beta-tester@example.com` (in beta-testers group) → always enabled
- Unit tests pass cho mọi targeting scenario

## Key Concepts
- **TargetingFilter**: built-in filter cho user/group targeting
- **ITargetingContextAccessor**: cung cấp user identity cho targeting evaluation
- **Audience**: {Users, Groups, DefaultRolloutPercentage, Exclusion}
- **Percentage rollout**: hash(userId + featureName) mod 100 < percentage
- **Canary release**: bật feature cho % nhỏ → monitor → tăng dần
- **Exclusion**: override percentage/group để luôn tắt với specific users/groups

## Resources
- [Targeting filter docs](https://learn.microsoft.com/en-us/azure/azure-app-configuration/howto-targetingfilter-aspnet-core)
- [ITargetingContextAccessor](https://github.com/microsoft/FeatureManagement-Dotnet/blob/main/src/Microsoft.FeatureManagement/Targeting/ITargetingContextAccessor.cs)
- [Canary releases - Martin Fowler](https://martinfowler.com/bliki/CanaryRelease.html)
