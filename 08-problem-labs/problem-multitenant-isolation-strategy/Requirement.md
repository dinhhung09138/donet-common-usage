# Problem Lab: Multi-Tenant Database Isolation Strategy

> **Category:** Architecture Decision
> **Effort:** 2–3 days
> **Technologies:** Finbuckle.MultiTenant EFCoreMultiTenantStore, dynamic DbContext, per-tenant connection string from Key Vault, EF Core per-tenant migration runner (Hangfire), IMultiTenantContextAccessor

---

## Scenario

A B2B SaaS platform is close to signing three enterprise contracts worth £2M ARR. Each enterprise customer's legal team requires dedicated database isolation for data residency compliance (GDPR, UK DPA, and one US customer with SOC2 requirements). The current shared database + tenant column model cannot satisfy these requirements. The platform needs to offer both isolation models without a full rewrite.

**Business impact:** £2M ARR at risk. Sales cannot close enterprise deals. The shared DB model also has a risk: a bug in any global query filter exposes all tenants' data simultaneously.

---

## The Problem / Requirement

**Functional requirements:**
- Existing small/medium tenants continue on shared DB (no migration)
- New enterprise tenants provisioned on dedicated databases
- Same application code serves both models transparently
- New tenant database: provisioned, migrated, and seeded automatically on sign-up

**Non-functional requirements:**
- Zero downtime for existing tenants during enterprise rollout
- Dedicated DB connection strings encrypted at rest in Azure Key Vault
- EF Core migrations applied to all tenant databases (shared and dedicated) in one command
- Background jobs must resolve correct tenant DB without an HTTP request context

**Architecture decision to make:**
- How to represent tenant strategy (shared vs dedicated) in configuration
- How to resolve the correct connection string per request
- How to run EF Core migrations across N tenant databases

---

## Solution Design

**Option A — Hard-code a switch per tenant:**
`if (tenantId == "enterprise") { connectionString = "..." }`. Doesn't scale past 5 tenants. Connection strings in code.

**Option B — Finbuckle.MultiTenant `EFCoreMultiTenantStore` with per-tenant Key Vault secrets (recommended):**
Tenant configuration stored in DB: `{ TenantId, ConnectionStringSecretName, IsolationStrategy }`. On each request, `ITenantResolver` resolves tenant from JWT claim, fetches config from store, resolves connection string from Key Vault (cached in-process). `DbContext` uses resolved connection string. Migrations run via Hangfire job that iterates all tenant configs.

**Why Option B:**
- New enterprise tenant = one DB record + one Key Vault secret — zero code change
- Key Vault: connection strings never in source control or environment variables
- Finbuckle handles tenant resolution and DbContext configuration — proven, battle-tested
- Migration runner as Hangfire job: one-command deploy to all tenant databases

```
Request (JWT: tenant_id = "enterprise-acme")
    │
    ▼
TenantResolutionMiddleware
    │ Resolve TenantInfo from EFCoreMultiTenantStore (in-process cache 5 min)
    │ TenantInfo: { Id: "enterprise-acme", SecretName: "db-conn-enterprise-acme", Strategy: Dedicated }
    │
    ▼
Key Vault: GetSecretAsync(secretName) ← cached in IDistributedCache
    │ Connection string: "Server=acme-sql.database.windows.net;..."
    │
    ▼
ApplicationDbContext (connection string set from TenantInfo)
    │
    └── All queries scoped to this tenant's database (dedicated)
        OR with HasQueryFilter(x => x.TenantId == currentTenantId) (shared)
```

---

## Implementation Tasks

1. **Design `TenantConfiguration` entity + `EFCoreMultiTenantStore`**
   - `TenantConfiguration`: TenantId, Identifier, Name, IsolationStrategy (Shared/Dedicated), ConnectionStringSecretName (Key Vault secret name), Active
   - Seed: 2 shared tenants (no secret name, use default connection), 1 dedicated tenant (Key Vault secret)
   - Acceptance: `ITenantStore.GetByIdentifierAsync("enterprise-acme")` returns dedicated tenant config

2. **Implement per-tenant connection string resolution with Key Vault cache**
   - Resolve `DefaultAzureCredential` → `SecretClient.GetSecretAsync(secretName)`
   - Cache resolved connection string: `IDistributedCache` with TTL 10 minutes
   - Fallback to shared connection string if `IsolationStrategy == Shared`
   - Acceptance: Dedicated tenant request uses dedicated connection string; shared tenant uses shared

3. **Override `DbContext.OnConfiguring()` with resolved connection string**
   - `ApplicationDbContext` accepts `ITenantInfo` via DI
   - `OnConfiguring`: if dedicated, use tenant connection string; if shared, use default + apply HasQueryFilter
   - Acceptance: Two concurrent requests — one shared tenant, one dedicated — each use correct DB (integration test with TestContainers)

4. **Implement tenant onboarding workflow (Hangfire job)**
   - Trigger: `POST /admin/tenants` with new tenant details
   - Step 1: Create Azure SQL database (Azure SDK `SqlDatabaseResource`)
   - Step 2: Store connection string in Key Vault
   - Step 3: Register tenant config in `TenantConfiguration` table
   - Step 4: Run EF Core migrations on new tenant DB (see next task)
   - Acceptance: New tenant provisioned end-to-end in < 2 minutes (measured, integration test)

5. **EF Core migration runner for all tenant databases**
   - Hangfire recurring job: `MigrationRunner` — fetches all active tenant configs, for each runs `dbContext.Database.MigrateAsync()`
   - Shared tenants: migrated via default DbContext
   - Dedicated tenants: migrated via per-tenant DbContext with resolved connection string
   - Acceptance: Apply new migration → Hangfire job runs against all 3 tenant DBs; verify schema updated in each

6. **`IMultiTenantContextAccessor` in background jobs (no HttpContext)**
   - Hangfire job receives `tenantId` parameter explicitly
   - Service resolves `TenantInfo` from store via `tenantId` — not from `IHttpContextAccessor`
   - Acceptance: Hangfire job runs for dedicated tenant — queries execute against correct dedicated DB

---

## Acceptance Criteria

- [ ] Shared tenant request: queries use shared DB with global query filter
- [ ] Dedicated tenant request: queries use dedicated DB (no global filter needed — entire DB is tenant-scoped)
- [ ] New tenant provisioned end-to-end via admin API: DB created, migrations applied, Key Vault secret stored, tenant record active
- [ ] Connection strings never in code or environment variables (Key Vault only)
- [ ] Hangfire migration runner applies new migration to all tenant DBs
- [ ] Hangfire job for dedicated tenant: correct DB used (no HttpContext)
- [ ] Two concurrent requests (shared + dedicated): each use correct DB (TestContainers integration test)

---

## Interview Talking Points

**Situation:** Three enterprise deals worth £2M ARR blocked because the shared database model couldn't satisfy data residency requirements. The platform needed to support both shared and dedicated database isolation without rewriting the data layer.

**Task:** Design and implement a multi-tenant isolation strategy that supports both models transparently from application code, with zero impact on existing shared tenants.

**Action:**
- Used Finbuckle.MultiTenant's `EFCoreMultiTenantStore` to store tenant isolation strategy as data — adding a new enterprise tenant is a DB record and a Key Vault secret, not a code change
- Overrode `DbContext.OnConfiguring()` to resolve connection strings from Azure Key Vault (cached 10 min) based on tenant config — shared tenants get the default connection + global query filter; dedicated tenants get their own connection string
- Implemented a Hangfire migration runner that iterates all tenant configurations and runs `Database.MigrateAsync()` against each — deploying a schema change to 20 dedicated tenants takes the same effort as deploying to 1

**Result:** All three enterprise deals closed within 2 months. Existing shared tenants were unaffected. First dedicated tenant provisioned in 90 seconds via the admin API.

**Follow-up questions to prepare:**
- "What if a dedicated tenant's Key Vault secret is rotated — does the app need to restart?" → No. The connection string is cached in `IDistributedCache` with TTL 10 minutes. After rotation, the old connection drains, and within 10 minutes all new requests use the rotated secret. Zero restart required.
- "How do you ensure dedicated tenant data is completely isolated — could a bug in the connection string resolution leak cross-tenant data?" → Two defenses: (1) dedicated DB has no other tenants' data — even a wrong filter returns nothing cross-tenant; (2) integration test with two concurrent requests verifies each uses a different connection string

---

## Key Concepts

`Finbuckle.MultiTenant` · `EFCoreMultiTenantStore` · `ITenantInfo` · `Per-tenant DbContext` · `Azure Key Vault` · `DefaultAzureCredential` · `EF Core HasQueryFilter` · `Hangfire migration runner` · `IMultiTenantContextAccessor`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
