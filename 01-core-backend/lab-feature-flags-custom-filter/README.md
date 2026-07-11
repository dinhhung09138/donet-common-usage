# Lab: Feature Flags — Custom IFeatureFilter

## Objectives
- Implement custom `IFeatureFilter` types encapsulating non-trivial business logic
- Build a `TimeWindowFilter` that only enables a flag within a configured time range
- Build an `ABTestFilter` that performs a stable, deterministic split based on a user ID seed
- Read strongly-typed parameters from configuration inside a filter
- Unit test custom filters against mocked evaluation contexts

## Key Concepts
`[FilterAlias]` · `FeatureFilterEvaluationContext` · `context.Parameters.Get<T>()` · `deterministic hashing (HashCode.Combine)` · `IContextualFeatureFilter<TContext>`

## Tasks
- [ ] Implement `TimeWindowFilter` (`[FilterAlias("TimeWindow")]`) that reads a `TimeWindowSettings { Start, End }` from `context.Parameters.Get<T>()` and returns whether the current UTC time falls within the window; configure `PeakHourPricing` to use it
- [ ] Implement `BrowserVersionFilter` (`[FilterAlias("BrowserVersion")]`) that parses the `User-Agent` header via regex and enables the flag only when the detected browser version meets a configured minimum (`BrowserVersionSettings { Browser, MinVersion }`)
- [ ] Implement `ABTestFilter` (`[FilterAlias("ABTest")]`) that derives a stable bucket from `HashCode.Combine(userId, featureName) % 100` and compares it against `ABTestSettings.GroupAPercentage`, guaranteeing the same user always lands in the same group
- [ ] Register all three filters with `builder.Services.AddFeatureManagement().AddFeatureFilter<TimeWindowFilter>().AddFeatureFilter<BrowserVersionFilter>().AddFeatureFilter<ABTestFilter>()`
- [ ] Write theory-based unit tests for `TimeWindowFilter` covering inside-window, outside-window, and boundary times
- [ ] Write a unit test for `ABTestFilter` asserting that 100 evaluations for the same user ID always produce the same group assignment
- [ ] Write a unit test for `BrowserVersionFilter` covering a matching Chrome version, a below-minimum version, and a missing/unparseable `User-Agent`

## Expected Output
- `PeakHourPricing` → enabled between 08:00 and 20:00 UTC, disabled outside that window
- `NewUIComponents` → enabled only for Chrome ≥ 120
- `CheckoutVariantA` → user A is always in group A, user B is always in group B
- Unit tests cover every filter's edge cases
- Changing filter parameters in `appsettings.json` changes behaviour immediately, no redeploy required

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
