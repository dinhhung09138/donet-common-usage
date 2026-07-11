# Lab: Strangler Fig Pattern

## Objectives
- Incrementally migrate functionality from a legacy monolith to a new service without a big-bang rewrite.
- Route traffic for a specific capability through a facade/proxy that decides whether to serve it from the legacy system or the new service.
- Manage data consistency during the migration window when both systems may need to read/write overlapping data.
- Define a rollback strategy for cutting traffic back to the legacy path if the new service misbehaves.

## Key Concepts
`Strangler Fig Pattern` · `Facade/Proxy Routing` · `Incremental Migration` · `Feature Flags` · `Dual Writes`

## Tasks
- [ ] Build a minimal "legacy monolith" endpoint that owns a piece of functionality (e.g., a pricing calculation).
- [ ] Build a new microservice implementing the same functionality independently.
- [ ] Add a facade/routing layer that sends a configurable percentage (or feature-flag-gated subset) of traffic to the new service and the rest to the legacy endpoint.
- [ ] Handle data consistency: either dual-write to both systems or have the new service read from the legacy data store during the transition.
- [ ] Increase the traffic percentage to the new service incrementally and verify parity between old and new responses.
- [ ] Document the rollback trigger and mechanism (flip the flag back to 0%).

## Expected Output
A facade endpoint that can shift traffic between legacy and new implementations via configuration, with logged evidence of gradual cutover (e.g., 0% → 50% → 100%) and no observable difference in response correctness.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
