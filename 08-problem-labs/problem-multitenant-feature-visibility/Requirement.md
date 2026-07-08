# Problem Lab: Multi-Tenant Feature Visibility (Show/Hide Modules per Subscription Tier)

> **Category:** Feature Building
> **Effort:** 2–3 days
> **Technologies:** Azure App Configuration, Finbuckle.MultiTenant, IFeatureManager, TargetingFilter, custom IFeatureFilter, IConfigurationRefresher

---

## Scenario

A B2B SaaS platform has three subscription tiers: Free, Pro, and Enterprise. Enterprise customers need access to modules like "Advanced Analytics" and "Bulk Export" that Free users should never see — in both the API (endpoints return 403) and the frontend (menu items hidden). The current implementation is a hardcoded `if (tier == "Enterprise")` scattered across 12 controllers. Sales needs to offer trial access to specific tenants without a code deploy.

**Business impact:** Sales is losing deals because enabling trial access for a prospect requires a hotfix and deployment. Enterprise customers see 403 on features they paid for when config changes. Every new feature gating requires 3-day dev work.

---

## The Problem / Requirement

**Functional requirements:**
- Show/hide API endpoints and UI modules based on subscription tier (Free / Pro / Enterprise)
- Admin can enable a feature for a specific tenant as an override (e.g., trial access) without code change
- Feature availability updates within 30 seconds — no redeployment required
- Tenant is resolved from JWT claim, not URL path

**Non-functional requirements:**
- Feature check must add < 5ms to each request (no DB call per request)
- Works in background jobs (IMultiTenantContextAccessor, not HttpContext)
- Works for API endpoints (`[FeatureGate]`) and also programmatic checks (`IFeatureManager.IsEnabledAsync`)

**Edge cases:**
- Tenant subscription tier changes mid-session — takes effect within refresh window
- Azure App Configuration temporarily unavailable — serve last-known config (stale-while-revalidate)
- Admin disables a feature for a tenant mid-request — 403 returned gracefully, not 500

---

## Solution Design

**Option A — Database flag per tenant per feature:**
Query DB on each request. Simple but: N DB calls per request, no runtime refresh, no UI for non-devs.

**Option B — Azure App Configuration + IFeatureManager with TargetingFilter (recommended):**
Feature flags stored in Azure App Config, keyed by feature name with labels per environment. Tenant subscription tier resolved at request time and injected as TargetingContext group. Per-tenant overrides stored as `Tenant:{tenantId}` audience entries. IConfigurationRefresher polls on sentinel key change — no redeployment.

**Why Option B:**
- No DB call per request — feature state cached in-process, refreshed from App Config on sentinel key change
- Per-tenant overrides = Audience entry in TargetingFilter: add `Tenant:{tenantId}` to 100% group
- Zero code deploy for sales to enable trial: update App Config in Azure portal → sentinel key change → all pods refresh within 30s

```
Request
  │
  ▼
TenantResolutionMiddleware (from JWT claim)
  │
  ▼
ITargetingContextAccessor.GetContextAsync()
  │  → Groups: ["Tier:Enterprise", "Tenant:tenant-abc"] (from JWT)
  │
  ▼
IFeatureManager.IsEnabledAsync("BulkExport")
  │  → TargetingFilter checks: is group in audience config?
  │
  ├── YES → allow request
  └── NO  → 403 Forbidden
```

---

## Implementation Tasks

1. **Set up Finbuckle.MultiTenant with JWT claim-based tenant resolution**
   - Resolve tenantId + subscriptionTier from JWT claims (`tenant_id`, `subscription_tier`)
   - Register `IMultiTenantContextAccessor` for DI
   - Acceptance: Integration test verifying tenant context set correctly from two different JWTs

2. **Configure Azure App Configuration feature flags with labels per environment**
   - Feature flags: `BulkExport`, `AdvancedAnalytics`, `APIRateLimit:High`, `AuditLog`
   - Label: `dev`, `staging`, `prod`
   - Sentinel key: `sentinel` — change this to trigger refresh across all pods
   - Acceptance: Feature flag toggleable from Azure portal without code change

3. **Implement `SubscriptionTierTargetingContextAccessor : ITargetingContextAccessor`**
   - Build TargetingContext with groups: `["Tier:{subscriptionTier}", "Tenant:{tenantId}"]`
   - Acceptance: Unit test — Pro tenant gets `["Tier:Pro", "Tenant:tenant-xyz"]` groups

4. **Configure TargetingFilter audience per feature flag**
   - `BulkExport`: audience groups = `["Tier:Enterprise", "Tier:Pro"]`
   - `AdvancedAnalytics`: audience groups = `["Tier:Enterprise"]`
   - Per-tenant override: add `"Tenant:trial-tenant-id"` to audience at 100%
   - Acceptance: Pro tenant can access BulkExport; Free tenant gets 403; trial tenant gets access despite Free tier

5. **Apply `[FeatureGate("BulkExport")]` to restricted endpoints**
   - Implement `IDisabledFeaturesHandler` to return RFC 7807 ProblemDetails with `403` and `feature_disabled` error code (not default 404)
   - Acceptance: Free user calls restricted endpoint → 403 with structured error body

6. **Implement dynamic refresh with sentinel key pattern**
   - `IConfigurationRefresher` registered; `UseAzureAppConfiguration()` middleware enabled
   - CacheExpirationInterval: 30 seconds
   - Sentinel key change in Azure portal triggers refresh within one cache window
   - Acceptance: Change feature flag in portal, wait 30s, verify API behavior changes without restart

7. **Test per-tenant trial override via Azure portal (no code)**
   - Add Free-tier test tenant's ID to `BulkExport` audience in App Config
   - Verify access granted within 30 seconds
   - Remove override; verify access revoked within 30 seconds
   - Acceptance: Full cycle documented — this is the sales trial enablement runbook

---

## Acceptance Criteria

- [ ] Free tenant: `GET /api/bulk-export` → 403 with structured error
- [ ] Pro tenant: `GET /api/bulk-export` → 200
- [ ] Enterprise tenant: `GET /api/advanced-analytics` → 200; Pro tenant → 403
- [ ] Trial override: add Free tenant to audience in App Config → access granted within 30s (no deploy)
- [ ] Remove override → access revoked within 30s
- [ ] `IFeatureManager` works in background Hangfire job (no HttpContext) via `IMultiTenantContextAccessor`
- [ ] Azure App Configuration unavailable → last-known config served (stale-while-revalidate verified)

---

## Interview Talking Points

**Situation:** Sales was losing deals because enabling trial access for a prospect required a hotfix and 3-day deployment cycle. Feature gating was hardcoded across 12 controllers.

**Task:** Design a feature visibility system that supports per-tier and per-tenant access control, changeable at runtime from the Azure portal without any code deploy.

**Action:**
- Replaced hardcoded `if (tier == "Enterprise")` with `IFeatureManager.IsEnabledAsync()` and `[FeatureGate]` attributes — centralizing feature control into Azure App Configuration
- Implemented `ITargetingContextAccessor` that builds TargetingContext groups from JWT claims (`Tier:Enterprise`, `Tenant:{id}`) — enabling TargetingFilter to grant/deny access per subscription tier
- Used Azure App Config sentinel key pattern to propagate changes to all pods within 30 seconds, replacing the 3-day deploy cycle with a portal update

**Result:** Sales could enable trial access for any prospect in 2 minutes via the Azure portal. Adding a new gated feature takes 30 minutes (add flag to App Config, add `[FeatureGate]` to endpoint). Zero hardcoded tier checks remain.

**Follow-up questions to prepare:**
- "What if the feature flag check fails due to App Config being unreachable?" → Stale-while-revalidate: last-known config served from in-process cache; fail-open or fail-closed configurable per feature
- "How do you gate UI menu items on the frontend?" → Same feature flags exposed via a `GET /api/features` endpoint that returns the enabled flag list for the current tenant — no separate configuration needed

---

## Key Concepts

`Azure App Configuration` · `IFeatureManager` · `ITargetingContextAccessor` · `TargetingFilter` · `IFeatureGate` · `Finbuckle.MultiTenant` · `IConfigurationRefresher` · `Sentinel key pattern` · `IDisabledFeaturesHandler`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
