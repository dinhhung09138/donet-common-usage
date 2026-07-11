# Lab: Feature Flags — Targeting Filter & Percentage Rollout

## Objectives
- Enable a feature flag for specific users/groups using `TargetingFilter`
- Implement `ITargetingContextAccessor` to supply user context to the targeting evaluator
- Configure percentage rollout for canary releases
- Verify targeting and rollout logic with tests

## Key Concepts
`TargetingFilter` · `ITargetingContextAccessor` · `Audience (Users, Groups, DefaultRolloutPercentage, Exclusion)` · `percentage rollout` · `canary release` · `stable hashing`

## Tasks
- [ ] Install `Microsoft.FeatureManagement.AspNetCore`; register targeting with `builder.Services.AddFeatureManagement().WithTargeting<AppTargetingContextAccessor>()`
- [ ] Implement `AppTargetingContextAccessor : ITargetingContextAccessor`, resolving `UserId` from the authenticated user's `ClaimTypes.NameIdentifier` and `Groups` from a `"subscription"` claim (falling back to `"anonymous"` for unauthenticated requests)
- [ ] Configure the `BetaDashboard` flag in `appsettings.json` with a `Targeting` filter: an explicit `Users` allowlist, `Groups` with per-group `RolloutPercentage` (e.g., `beta-testers: 100`, `premium: 50`), and a `DefaultRolloutPercentage`
- [ ] Simulate a staged canary rollout by walking `DefaultRolloutPercentage` through 5% → 25% → 50% → 100%, and describe what to monitor at each stage (errors/latency, business metrics, broader rollout)
- [ ] Add an `Exclusion` block (specific users and groups, e.g., `internal-qa`) so excluded identities are always denied regardless of rollout percentage
- [ ] Write theory-based unit tests covering: a user in the explicit allowlist, a user relying on group rollout percentage, and an excluded user/group — asserting the evaluator returns the expected enabled/disabled result for each

## Expected Output
- `alice@example.com` → feature enabled (explicit allowlist)
- `regular@example.com` → ~`DefaultRolloutPercentage`% chance of being enabled
- `excluded@example.com` → always disabled (Exclusion)
- A user in the `beta-testers` group → always enabled (100% group rollout)
- Unit tests pass for every targeting scenario

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
