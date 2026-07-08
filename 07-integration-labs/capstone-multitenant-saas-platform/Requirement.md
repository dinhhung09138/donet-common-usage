# Capstone: Multi-Tenant SaaS Platform

## Business Context

Build a SaaS backend where multiple companies (tenants) share the same infrastructure but have fully isolated data, per-tenant feature flags, and subscription billing. This is the core architecture question at Toptal domain expert interviews and Arc.dev senior screens.

## Prerequisite Labs

- `lab-multitenant-authentication`
- `lab-stripe-payments`
- `lab-output-caching`
- `lab-feature-flags-azure-appconfig`
- `lab-ef-core-unit-of-work`
- `lab-options-pattern`
- `lab-rate-limiting-aspnetcore`

## Functional Requirements

- Tenant onboarding: registration creates isolated tenant record + admin user
- Per-tenant data isolation: tenants cannot access each other's data
- Subscription tiers (Free, Pro, Enterprise) with Stripe billing
- Per-tenant feature flags via Azure App Configuration (e.g., "enable-ai-search" for Enterprise only)
- Tenant admin can invite users and assign roles within their tenant
- Usage metering: track API calls per tenant per day for billing purposes

## Non-Functional Requirements

- Data isolation must hold even if a developer forgets a WHERE clause (global query filter enforced at EF Core level)
- Tenant resolution < 1ms added latency (header-based + cached tenant lookup)
- Feature flag refresh without restart (sentinel key pattern, 30s cache)
- Rate limiting partitioned per tenant (not per IP): Free tier 100 req/min, Pro 1000 req/min

## Architecture

```
Request arrives:
  → TenantResolutionMiddleware reads X-Tenant-Id header (or subdomain)
  → resolves Tenant from cache (IMemoryCache) or DB
  → sets ITenantInfo in HttpContext

EF Core:
  → ApplicationDbContext has global query filter: .Where(e => e.TenantId == _tenantId)
  → UoW automatically stamps TenantId on new entities

Feature flags:
  → IFeatureManager reads from Azure App Config with label = tenantTier
  → IConfigurationRefresher polls sentinel key every 30s

Rate limiting:
  → partition key = tenantId from claims
  → policy = TokenBucketRateLimiter with per-tier limits from IOptionsMonitor<RateLimitOptions>

Billing:
  → Stripe subscription created at onboarding
  → invoice.paid / customer.subscription.deleted webhooks update TenantSubscription
```

## Implementation Steps

1. **Tenant model:** `Tenant`, `TenantSubscription`, `TenantUser` entities; `TenantId` (Guid) as partition key
2. **Finbuckle.MultiTenant:** configure `WithEFCoreStore` + `WithHeaderStrategy("X-Tenant-Id")`
3. **EF Core global query filter:** apply `HasQueryFilter(e => e.TenantId == currentTenantId)` via base entity class
4. **Tenant resolution middleware:** resolve + cache tenant; short-circuit 401 if unknown tenant
5. **Per-tenant options:** `IOptionsMonitor<TenantRateLimitOptions>` — values stored in Azure App Config per tenant label
6. **Feature flags:** `IFeatureManager` with `TargetingFilter` for tier-based rollout; sentinel key refresh
7. **Stripe subscriptions:** create customer + subscription at onboarding; webhook handler for lifecycle events
8. **Usage metering:** `IActionFilter` increments Redis counter `usage:{tenantId}:{date}`; daily Hangfire job reads counters and appends to usage log
9. **Rate limiting:** `AddRateLimiter` with partition key = `TenantId` claim; per-tier limits
10. **Auth:** multi-tenant JWT — `tenantId` claim in token, validated against resolved tenant
11. **Integration tests:** TestContainers + multiple tenant contexts; verify cross-tenant query isolation

## Expected Deliverables

- Working API demonstrating tenant isolation (integration test that proves cross-tenant data leakage is impossible)
- Architecture diagram: tenant resolution → EF Core filter → response
- ADR: "Shared DB with global query filter vs separate DB per tenant — decision criteria"
- PR description covering the EF Core isolation approach

## Interview Talking Points

- How do you guarantee tenant isolation if a developer writes a raw SQL query that bypasses EF Core? (raw SQL must include tenant filter; Dapper queries go through a tenant-aware wrapper)
- When would you choose separate DB per tenant over shared DB? (compliance requirements, large tenants, noisy neighbour, different backup schedules)
- How does Finbuckle resolve the tenant in a background job (no HttpContext)? (ITenantInfo set manually or per-job context)
- How do you handle a tenant whose subscription expires mid-request? (IOptionsMonitor refresh + 402 response)
- What happens to the global query filter when using `IgnoreQueryFilters()`? (dangerous — only use for admin/reporting endpoints with explicit authorization check)
