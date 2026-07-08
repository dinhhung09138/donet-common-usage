# Problem Lab: IDOR Tenant Data Leak

> **Category:** Production Incident
> **Effort:** 1–2 days
> **Technologies:** Finbuckle.MultiTenant, EF Core HasQueryFilter, IAuthorizationService resource-based auth, ISaveChangesInterceptor, claims-based tenant resolution

---

## Scenario

A penetration test on a multi-tenant SaaS platform reveals that a standard user can access another tenant's invoices by simply changing the `{tenantId}` in the URL path. The vulnerability exists in 6 endpoints and has been present for 18 months. The legal team asks whether any actual unauthorized data access occurred.

**Business impact:** GDPR Article 32 violation. Contractual breach with enterprise customers (data residency clauses). Mandatory breach notification if any data was accessed. Potential loss of 3 enterprise contracts.

---

## The Problem

**Symptoms:**
- Any authenticated user can call `GET /tenants/{anyTenantId}/invoices` and receive data
- The controller only checks `[Authorize]` (user is logged in) — not whether `tenantId` matches the user's tenant claim
- EF Core queries do not filter by tenant — the `tenantId` URL parameter is passed directly to the query without ownership check

**Root cause analysis:**
- `tenantId` taken from URL path parameter, not from the authenticated user's JWT claim — attacker controls the parameter
- No global EF Core query filter for tenant isolation — every query can return any tenant's data
- Authorization checks only confirm the user is authenticated, not that they own the requested resource (IDOR = Insecure Direct Object Reference)
- No audit log to reconstruct which data was accessed by which users

**Constraints:**
- Fix must not change the external API contract (URLs remain the same for legitimate clients)
- Fix must be fully retroactive — all 6 affected endpoints

---

## Solution Design

**Option A — Manually add `WHERE TenantId = @userTenantId` to each query:**
Fragile. Easy to miss in future endpoints. Doesn't prevent a developer from forgetting.

**Option B — EF Core global query filter + resource-based authorization + audit interceptor (recommended):**
`HasQueryFilter(x => x.TenantId == currentTenantId)` — every query automatically scoped. Claims-based tenant resolution — `tenantId` always from JWT, never from URL. `ISaveChangesInterceptor` writes audit log on every read/write.

**Why Option B:**
- Global query filter is structural — impossible to forget. A developer must explicitly call `IgnoreQueryFilters()` to bypass it
- Claims-based resolution: even if the URL has a different `tenantId`, the query always uses the authenticated user's tenant
- Audit interceptor provides the evidence trail the legal team needs

```
Before fix:
  GET /tenants/other-tenant/invoices
  Controller: var invoices = _db.Invoices.Where(i => i.TenantId == tenantIdFromUrl)
  → Returns other tenant's data (IDOR)

After fix:
  JWT claim: tenant_id = "my-tenant"
  GET /tenants/other-tenant/invoices
  Controller: var invoices = _db.Invoices.ToListAsync()
  EF Core global filter: WHERE TenantId = 'my-tenant' (from claim, not URL)
  → Returns only authenticated user's tenant data
  ISaveChangesInterceptor writes: { UserId, TenantId, Resource, Action, Timestamp }
```

---

## Implementation Tasks

1. **Implement `ITenantClaimsResolver` — always resolve from JWT, never URL**
   - Extract `tenant_id` claim from `IHttpContextAccessor`
   - Throw `UnauthorizedAccessException` if claim is missing
   - Register as scoped service
   - Acceptance: Unit test — URL has tenantId "B", JWT claim has "A" → resolver returns "A"

2. **Add EF Core global query filter on all tenant-scoped entities**
   - `HasQueryFilter(x => x.TenantId == _tenantResolver.CurrentTenantId)`
   - Acceptance: Call `Invoices.ToListAsync()` as Tenant B while JWT claims Tenant A → returns empty, not Tenant B's data

3. **Add `IAuthorizationService` resource-based authorization on each endpoint**
   - `IAuthorizationRequirement`: `TenantOwnershipRequirement` — checks `resource.TenantId == user.TenantId`
   - Apply to all 6 affected endpoints
   - Acceptance: Tenant A user calls invoice endpoint with Tenant B's invoiceId → 403 Forbidden

4. **Implement `ISaveChangesInterceptor` for access audit log**
   - Log every read (via custom `DbCommandInterceptor`) and write: `{ UserId, TenantId, EntityType, EntityId, Action, IpAddress, Timestamp }`
   - Store in append-only `AuditLog` table (EF Core owned entity, no UPDATE/DELETE)
   - Acceptance: Audit log entry created on every `SaveChangesAsync` call

5. **Forensic query: reconstruct access history from Application Insights + logs**
   - Query Application Insights for any cross-tenant URL pattern: `/tenants/{tenantId}/` where `tenantId ≠ JWT tenant claim`
   - Document findings for legal team
   - Acceptance: Query returns zero results from the deployment date (confirming no confirmed access) OR identified incidents documented

6. **Integration test for each of the 6 affected endpoints**
   - Test: User with Tenant A JWT calls endpoint with Tenant B resource ID → 403
   - Test: User with Tenant A JWT calls endpoint with Tenant A resource ID → 200
   - Acceptance: All 12 tests pass (2 per endpoint × 6 endpoints)

---

## Acceptance Criteria

- [ ] `GET /tenants/{anyOtherId}/invoices` with Tenant A JWT → returns only Tenant A's invoices (EF global filter)
- [ ] Accessing another tenant's specific resource by ID → 403, not 200 (resource-based auth)
- [ ] `tenantId` in URL path has no effect on query results (claims always win)
- [ ] Every data access written to append-only audit log
- [ ] Integration test: cross-tenant access attempt → 403 (6 endpoints × 2 scenarios)
- [ ] `IgnoreQueryFilters()` usage banned by architecture test (NetArchTest)

---

## Interview Talking Points

**Situation:** Pen test found that any authenticated user could read another tenant's invoices by changing the tenantId URL parameter. Bug existed for 18 months across 6 endpoints. Legal needed to know if data was actually accessed.

**Task:** Fix the IDOR vulnerability system-wide, not just in 6 endpoints, and provide a forensic audit trail.

**Action:**
- Added an EF Core global query filter driven by the JWT `tenant_id` claim — every query is automatically scoped to the authenticated user's tenant without any per-endpoint code change
- Added `ISaveChangesInterceptor` to write an append-only audit log for every data access — providing the forensic trail the legal team needed to assess exposure
- Added a NetArchTest rule banning `IgnoreQueryFilters()` except in explicitly whitelisted admin contexts — making it structurally impossible for a future developer to accidentally bypass the filter

**Result:** All 6 endpoints fixed in one PR. Zero subsequent IDOR findings in follow-up pen test. Legal team cleared the incident after forensic query showed no cross-tenant URL patterns before the fix. Enterprise contracts retained.

**Follow-up questions to prepare:**
- "What is IDOR and how is it different from a broken authentication bug?" → IDOR (Insecure Direct Object Reference) is an authorization bug: the user is correctly authenticated but the system doesn't check that they own the resource they're requesting. Broken authentication means the user's identity itself isn't verified.
- "How do you prevent a future developer from adding `IgnoreQueryFilters()` carelessly?" → NetArchTest rule in the architecture test suite: any usage of `IgnoreQueryFilters()` outside the `AdminRepository` class fails the build.

---

## Key Concepts

`IDOR` · `EF Core HasQueryFilter` · `Global query filter` · `IAuthorizationService` · `Resource-based authorization` · `ISaveChangesInterceptor` · `Append-only audit log` · `Claims-based tenant resolution` · `Finbuckle.MultiTenant` · `NetArchTest`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
