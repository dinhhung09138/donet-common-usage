# Lab: Minimal API Endpoint Filters

## Objectives
- Implement `IEndpointFilter` for Minimal API and understand how it differs from MVC `ActionFilter`
- Build a composable filter pipeline: validation, timing, idempotency key check
- Short-circuit the pipeline to return early responses without reaching the endpoint handler
- Apply filters at route group level vs single endpoint level

## Key Concepts
`IEndpointFilter` · `InvokeAsync` · `EndpointFilterInvocationContext` · `AddEndpointFilter` · `route group filter` · `short-circuit` · `vs ActionFilter` · `filter execution order`

## Tasks
- [ ] Create a `ValidationFilter<TRequest>` that reads `TRequest` from the endpoint arguments, runs FluentValidation, and short-circuits with 422 if invalid — eliminating manual validation calls in every handler
- [ ] Create a `TimingFilter` that measures handler execution time and appends an `X-Response-Time-Ms` header using `Stopwatch`
- [ ] Create an `IdempotencyFilter` that reads an `Idempotency-Key` header, checks a Redis cache, and returns the cached response if the key was already processed — short-circuiting the handler
- [ ] Apply `ValidationFilter` and `TimingFilter` to a route group using `routeGroup.AddEndpointFilter<TimingFilter>()`; verify both filters execute for all group endpoints
- [ ] Apply `IdempotencyFilter` only to the `POST /orders` endpoint; verify GET endpoints are not affected
- [ ] Demonstrate filter execution order: add three filters with `Console.WriteLine` and confirm the pipeline is LIFO (last registered executes outermost)
- [ ] Compare with MVC `ActionFilter`: write the equivalent `ValidationActionFilter : IActionFilter`; document the differences (`IEndpointFilter` works with Minimal API and is interface-based; `ActionFilter` is attribute-based and MVC-only)
- [ ] Write integration tests asserting that invalid input returns 422, a duplicate idempotency key returns the cached response, and the `X-Response-Time-Ms` header is present

## Expected Output
A Minimal API with a composable filter pipeline (validation, timing, idempotency), correct short-circuit behaviour, and integration tests verifying each filter in isolation.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
