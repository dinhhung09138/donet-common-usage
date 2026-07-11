# Lab: Feature Flags with Microsoft.FeatureManagement

## Objectives
- Use `Microsoft.FeatureManagement` to toggle features without redeploying
- Apply feature flags at controller, service, and Razor view level
- Understand the feature flag lifecycle and how to manage it in production
- Verify feature flag behaviour with unit tests

## Key Concepts
`IFeatureManager` · `[FeatureGate]` · `IFeatureFilter` · `IDisabledFeaturesHandler` · `feature flag lifecycle` · `decoupling deployment from release`

## Tasks
- [ ] Install `Microsoft.FeatureManagement.AspNetCore`; register it in `Program.cs` with `builder.Services.AddFeatureManagement()`
- [ ] Define flags in `appsettings.json` (`NewCheckoutFlow`, `BetaRecommendations`, `DarkMode`, `MaintenanceMode`)
- [ ] Inject `IFeatureManager` into a service (e.g., `CheckoutService`) and branch logic with `IsEnabledAsync("NewCheckoutFlow")` between new and legacy flows
- [ ] Apply `[FeatureGate("BetaRecommendations")]` to a Minimal API endpoint and to an MVC controller action; confirm the gated route returns 404 when the flag is disabled
- [ ] Implement a custom `IDisabledFeaturesHandler` (e.g., `RedirectDisabledFeatureHandler`) to return 503 instead of 404 when a feature is disabled, and register it via `UseDisabledFeaturesHandler`
- [ ] Use the `<feature>` Razor Tag Helper (with and without `negate="true"`) to conditionally render markup based on the `DarkMode` flag
- [ ] Write a unit test with a mocked `IFeatureManager` (e.g., via NSubstitute) asserting that `CheckoutService` selects the new flow when the flag is enabled and the legacy flow when disabled

## Expected Output
- `GET /api/checkout` → 200 with the new flow when the flag is enabled, legacy flow when disabled
- `GET /api/recommendations` → 404 when `BetaRecommendations: false`
- Unit tests pass for both flag states
- Changing a flag in `appsettings.json` changes behaviour immediately (hot reload), with no redeploy required

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
