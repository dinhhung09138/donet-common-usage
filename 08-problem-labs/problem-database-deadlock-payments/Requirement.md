# Problem Lab: SQL Server Deadlock Under Concurrent Payment Approvals

> **Category:** Production Incident
> **Effort:** 1–2 days
> **Technologies:** SQL Server Extended Events, canonical lock order, EF Core IExecutionStrategy, Polly 1205 retry, IsolationLevel, Dapper transactions, Serilog structured logging

---

## Scenario

A payments processing service handles concurrent payment approvals. Under Black Friday load (500 concurrent approvals), SQL Server starts reporting deadlock victim errors (error 1205). A subset of payments fail silently — the exception is logged but the payment status is never updated, leaving orders stuck in PENDING indefinitely. Operations is paged at 2am.

**Business impact:** 3% of payments during peak hours stuck in PENDING. Customers receive no confirmation email. Manual reconciliation required the next business day. One large B2B customer threatens to cancel their contract.

---

## The Problem

**Symptoms:**
- SQL Server error log: `Transaction was deadlocked on lock resources with another process`
- Application Insights: sporadic `SqlException` with number 1205 during peak load
- Orders stuck in `PENDING` status (payment succeeded but status update failed)
- Exception is caught in a `Task.Run` fire-and-forget — status update never retried

**Root cause analysis:**
- Two concurrent transactions updating related rows in different order: Transaction A locks `Payment` then `Account`; Transaction B locks `Account` then `Payment` — classic deadlock cycle
- No deadlock retry in the application layer — SQL Server picks one transaction as victim, throws error 1205, but the application swallows the exception in a fire-and-forget `Task.Run`
- Isolation level: default `READ COMMITTED` with implicit locking — upgrading to SNAPSHOT isolation would eliminate the deadlock but requires careful testing
- Missing index on `Account.TenantId` causes lock escalation — row lock → page lock → higher deadlock probability

**Constraints:**
- Cannot take DB offline to change isolation level
- Fix must not increase P99 latency significantly

---

## Solution Design

**Option A — Switch to SNAPSHOT isolation:**
Eliminates read-write deadlocks. Requires `ALTER DATABASE ... SET ALLOW_SNAPSHOT_ISOLATION ON` (online, no downtime) and setting `IsolationLevel.Snapshot` in code. Not suitable as a 2am emergency fix.

**Option B — Canonical lock order + deadlock retry + index (recommended):**
Ensure all transactions acquire locks in the same order (Payment always before Account). Add `IExecutionStrategy` retry on SQL error 1205. Add missing index to reduce lock escalation. Deploy without DB downtime.

**Why Option B:**
- Canonical lock order eliminates the deadlock cycle immediately — no isolation level change needed
- Application-level retry is defense-in-depth: even if a deadlock occurs, the transaction is retried transparently
- Index deployment is online (no blocking)

```
Before fix:
  T1: LOCK Payment(id=1) → wait for Account(id=2)
  T2: LOCK Account(id=2) → wait for Payment(id=1)
  → DEADLOCK

After fix (canonical order: always Payment first, then Account):
  T1: LOCK Payment(id=1) → LOCK Account(id=2) → commit
  T2: LOCK Payment(id=1) → wait → LOCK Account(id=2) → commit
  → SERIALIZED, NO DEADLOCK
```

---

## Implementation Tasks

1. **Capture deadlock graph with SQL Server Extended Events**
   - Create Extended Events session targeting `xml_deadlock_report`
   - Reproduce deadlock under load (use NBomber with 500 concurrent requests)
   - Analyze deadlock graph: identify which resources are locked in which order
   - Acceptance: Deadlock graph captured showing canonical lock order violation

2. **Fix canonical lock order: always acquire Payment lock before Account lock**
   - In both `ApprovePaymentHandler` and `AccountBalanceUpdater`: acquire rows in same order
   - Use `SELECT ... WITH (UPDLOCK)` on the first resource before beginning the transaction
   - Acceptance: Deadlock graph no longer produced under 500 concurrent approvals (NBomber test)

3. **Add EF Core `IExecutionStrategy` retry on SQL error 1205**
   - Implement custom `SqlServerRetryingExecutionStrategy` that retries on error 1205
   - Max retry count: 3; exponential delay with jitter
   - Log each retry with Serilog: `Log.Warning("Deadlock retry {RetryCount} for PaymentId {PaymentId}", ...)`
   - Acceptance: Simulate deadlock (two concurrent txns with artificial delay) — verify retry succeeds and payment status updated

4. **Fix fire-and-forget swallowing the exception**
   - Remove `Task.Run` wrapper — execute synchronously in the request handler
   - Add `try/catch` with structured logging: `{ PaymentId, CustomerId, ErrorCode, RetryCount }`
   - Acceptance: SqlException 1205 now logged with full context AND retried; no silent swallow

5. **Add missing index on `Account.TenantId` to reduce lock escalation**
   - Create index online: `CREATE INDEX IX_Account_TenantId ON Account(TenantId) WITH (ONLINE = ON)`
   - Acceptance: Lock escalation events drop to zero in Extended Events session

6. **Add Polly retry policy as defense-in-depth on the service layer**
   - `Policy.Handle<SqlException>(ex => ex.Number == 1205).WaitAndRetryAsync(3, attempt => TimeSpan.FromMilliseconds(Math.Pow(2, attempt) * 100 + jitter))`
   - Acceptance: Integration test with artificial deadlock — Polly retries and payment completes

7. **Load test: NBomber 500 concurrent approvals before/after**
   - Baseline: deadlock rate, P99 latency, PENDING orders count
   - After fix: zero deadlocks, PENDING orders drop to zero, P99 < 200ms
   - Acceptance: NBomber report shows zero SqlException 1205 after fix

---

## Acceptance Criteria

- [ ] Deadlock graph captured and root cause documented (canonical lock order violation)
- [ ] 500 concurrent payment approvals: zero deadlocks after canonical lock order fix (NBomber)
- [ ] `IExecutionStrategy` retry: deadlock → transparent retry → payment succeeds (integration test)
- [ ] No more silent exception swallowing: every SqlException 1205 logged with structured context
- [ ] Missing index deployed online (no table lock)
- [ ] P99 latency not increased by retry mechanism (< 200ms, NBomber report)

---

## Interview Talking Points

**Situation:** 3% of payments stuck in PENDING during peak load. SQL Server deadlock victims logged but exceptions swallowed in fire-and-forget Task.Run. Customers received no confirmation.

**Task:** Diagnose the deadlock root cause and implement fixes that prevent recurrence and handle unavoidable deadlocks gracefully.

**Action:**
- Used SQL Server Extended Events `xml_deadlock_report` to capture the deadlock graph and identify that Transaction A locked `Payment` then `Account` while Transaction B did the reverse — a classic cycle
- Fixed the canonical lock order: all code paths now acquire the `Payment` row lock before the `Account` row, eliminating the deadlock cycle entirely
- Added `IExecutionStrategy` retry on error 1205 as defense-in-depth — if a deadlock still occurs, the transaction retries up to 3× with exponential backoff rather than failing

**Result:** Deadlock rate dropped from 3% to zero under the same load profile. The `IExecutionStrategy` retry has fired zero times in production in 4 months — the lock order fix was the real solution; retry is defense-in-depth.

**Follow-up questions to prepare:**
- "Why not just use SNAPSHOT isolation?" → SNAPSHOT eliminates read-write deadlocks but requires testing all transactional code for correctness under optimistic concurrency semantics — not suitable as a 2am fix. Canonical lock order is surgical and safe.
- "How do you reproduce a deadlock in a test environment?" → Two concurrent tasks with `Thread.Sleep` between the lock acquisitions to guarantee interleaving. NBomber with high concurrency also reproduces it reliably on the real DB.

---

## Key Concepts

`SQL Server Extended Events` · `Deadlock graph` · `Canonical lock order` · `UPDLOCK hint` · `EF Core IExecutionStrategy` · `Polly retry on SqlException 1205` · `SNAPSHOT isolation` · `Lock escalation` · `Structured logging`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
