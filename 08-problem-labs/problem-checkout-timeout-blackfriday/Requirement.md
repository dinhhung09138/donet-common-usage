# Problem Lab: Checkout API Timeout Under Black Friday Load

> **Category:** Production Incident
> **Effort:** 2 days
> **Technologies:** EF Core (compiled queries, no-tracking), Redis cache-aside, Output Caching, Polly bulkhead + ConcurrencyLimiter, SQL Server execution plans, BenchmarkDotNet

---

## Scenario

An e-commerce checkout API handles normal load at 200ms P99. On Black Friday, traffic spikes 20× and the endpoint degrades to 8+ seconds, causing basket abandonment. On-call engineers see SQL Server CPU at 100% and EF Core connection pool exhaustion in Application Insights. The engineering team has 2 hours to fix before the peak window.

**Business impact:** 40% basket abandonment rate during peak — £120k in lost revenue in 4 hours. SLA breach triggers penalty clause with the payment processor.

---

## The Problem

**Symptoms:**
- P99 latency: 200ms (normal) → 8,400ms (peak)
- SQL Server CPU: 100%, I/O wait 80%
- Application Insights: `ConnectionPool Exhausted` errors on DbContext
- EF Core slow query log: two queries each > 2s

**Root cause analysis:**
- Missing composite index on `Orders (TenantId, Status, CreatedAt)` — full table scan on every checkout price recalculation
- EF Core tracking enabled on read-only product catalog queries — unnecessary change-tracker overhead × 20 concurrent requests
- Product catalog loaded from DB on every checkout (no caching) — same 200 rows fetched 20× per second
- Connection pool size at default (100) — insufficient for 20× traffic; requests queue waiting for connections
- No concurrency limit — all 20× traffic hits DB simultaneously; no load shedding

**Constraints:**
- Cannot change the DB schema mid-incident (no migration deployment)
- Cannot reduce traffic — this is the expected peak

---

## Solution Design

**Option A — Add index only:**
Fixes the worst query. Fast to deploy. Doesn't address caching or connection exhaustion for next spike.

**Option B — Index + Redis cache-aside + compiled queries + Polly load shed (recommended):**
Address all root causes in order of impact. Index applied online (no table lock). Redis caches product catalog (cold data). Compiled queries eliminate per-request query compilation overhead. ConcurrencyLimiter sheds excess load with 429 rather than crashing.

**Why Option B:**
- Index alone doesn't prevent connection pool exhaustion at 20× load
- Redis cache eliminates 80% of product catalog DB reads (catalog changes < once/hour)
- ConcurrencyLimiter protects DB during future spikes — fail fast rather than cascade

```
Request
  │
  ▼
ConcurrencyLimiter (max 50 concurrent) ──► 429 if exceeded (load shed)
  │
  ▼
Product Catalog read ──► Redis cache-aside (TTL: 5 min)
  │ MISS only             └──► DB (compiled no-tracking query) ──► Redis SET
  │
  ▼
Order price recalculation ──► DB (compiled query + index hit)
  │
  ▼
200 OK
```

---

## Implementation Tasks

1. **Diagnose: capture slow query plan and identify missing index**
   - Enable EF Core slow query logging: `optionsBuilder.LogTo(..., LogLevel.Warning)`
   - Run `SET STATISTICS IO ON` and `SHOWPLAN_ALL` on the identified queries
   - Confirm missing index on `Orders (TenantId, Status, CreatedAt)`
   - Acceptance: EXPLAIN plan shows index seek, not table scan, after adding index

2. **Add composite index online (no blocking)**
   - EF Core migration: `CREATE INDEX CONCURRENTLY` equivalent — `WITH (ONLINE = ON)` on SQL Server
   - Measure query time before/after with BenchmarkDotNet
   - Acceptance: Query time drops from 2,100ms to < 15ms

3. **Implement Redis cache-aside for product catalog**
   - Cache key: `catalog:products:{tenantId}` — TTL: 5 minutes
   - Serialize with `System.Text.Json`; cache `IList<ProductDto>` not EF entities
   - Cache stampede protection: use `IDistributedLock` (RedLock) on cache miss
   - Acceptance: Second request hits Redis (0ms); no DB call for 5 minutes; BenchmarkDotNet comparison

4. **Convert product catalog query to compiled no-tracking query**
   - `EF.CompileAsyncQuery()` for product catalog fetch
   - Add `.AsNoTracking()` to all read-only queries in checkout path
   - Acceptance: BenchmarkDotNet shows 35% reduction in allocation per request

5. **Add ASP.NET Core ConcurrencyLimiter as load shedder**
   - `AddRateLimiter` with `ConcurrencyLimiter(permitLimit: 50)`
   - `OnRejected`: return 429 with `Retry-After: 2` header
   - Acceptance: 100 concurrent requests → 50 succeed, 50 return 429 (NBomber load test)

6. **Add Polly bulkhead on DB calls in checkout service**
   - `BulkheadPolicy(maxParallelization: 20, maxQueuingActions: 10)`
   - Acceptance: Bulkhead rejects excess calls rather than queuing to DB exhaustion

7. **Load test before/after with NBomber**
   - Scenario: 500 virtual users, 30-second ramp
   - Baseline (before): P99 > 8s, error rate 15%
   - Target (after): P99 < 300ms, error rate < 1%
   - Acceptance: NBomber report shows target met

---

## Acceptance Criteria

- [ ] Missing index identified from query plan (before screenshot included in PR)
- [ ] After index: checkout query < 15ms on 100k row table (BenchmarkDotNet)
- [ ] Redis cache-aside: product catalog reads DB once per 5 minutes (integration test)
- [ ] NBomber load test: 500 VU, P99 < 300ms, error rate < 1% (after all fixes)
- [ ] ConcurrencyLimiter: 429 returned at limit, not connection pool exhaustion
- [ ] All changes deployable without DB downtime (online index build)

---

## Interview Talking Points

**Situation:** Checkout API hit 8+ seconds P99 on Black Friday. SQL Server CPU at 100%, EF Core connection pool exhausted, 40% basket abandonment, £120k lost in 4 hours.

**Task:** Diagnose the root cause and fix within 2 hours before the next traffic peak.

**Action:**
- Ran Application Insights slow query analysis and identified two queries causing full table scans — added a composite index with `ONLINE = ON` (no blocking), which cut those queries from 2,100ms to 15ms
- Added Redis cache-aside for the product catalog (read-only, changes once per hour) — eliminated 80% of DB reads on the hot checkout path
- Added ASP.NET Core `ConcurrencyLimiter` as a load shedder — at 50 concurrent requests the system returns 429 rather than cascading to DB exhaustion

**Result:** P99 latency dropped from 8,400ms to 180ms under the same load profile. Zero SLA breach in the following peak window. The Redis cache layer also reduced average DB CPU by 60% outside of peak hours.

**Follow-up questions to prepare:**
- "What if the Redis cache serves stale product prices during a flash sale?" → Tag-based eviction: pricing service publishes `ProductUpdated` event → consumer calls `IOutputCacheStore.EvictByTagAsync("catalog")` — stale window < 1s
- "How would you find the root cause if you had no Application Insights?" → dotnet-counters for connection pool; `sys.dm_exec_query_stats` on SQL Server for top queries by CPU; `DBCC SQLPERF('sys.dm_os_wait_stats')` for wait types

---

## Key Concepts

`EF Core compiled queries` · `AsNoTracking` · `Redis cache-aside` · `Cache stampede` · `Output Caching` · `ConcurrencyLimiter` · `Polly bulkhead` · `SQL execution plan` · `BenchmarkDotNet` · `NBomber`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] PR added to real-world-cases → `technical-interview/real-world-cases/`
