# Problem Lab: Payment Double Charge from HTTP Retry

> **Category:** Production Incident
> **Effort:** 2 days
> **Technologies:** Stripe Idempotency-Key, MassTransit outbox, Polly retry filtering, Redis idempotency store, EF Core TransactionScope, FixedTimeEquals

---

## Scenario

A fintech startup receives 12 customer complaints about double charges after an AWS network blip caused HTTP timeouts. Investigation shows the Stripe PaymentIntent was created and succeeded, but the API retried the POST request because it timed out before receiving the 200 response — creating a second PaymentIntent. The company faces £40,000 in refunds and a potential FCA compliance review.

**Business impact:** £40k in refunds processed within 48 hours. Risk of FCA compliance action. Trust erosion with affected customers.

---

## The Problem

**Symptoms:**
- 12 customers charged twice within a 15-minute window
- Stripe dashboard shows two PaymentIntents per affected order (different IDs, both succeeded)
- Application logs show HTTP timeout on first Stripe call, followed immediately by a retry

**Root cause analysis:**
- No Stripe `Idempotency-Key` header on `PaymentIntent.Create` — each call creates a new charge, even with identical parameters
- Polly retry policy retries on `HttpRequestException` (timeout) without filtering — should retry transient errors only, never payment creation
- No outbox pattern — the order record write and the payment call are not atomic; server can crash after payment succeeds but before order is updated
- Webhook processing is not idempotent — `payment_intent.succeeded` event processed twice on Stripe retry

**Constraints:**
- Cannot disable retries globally — other HTTP calls (product catalog, shipping) need retry
- Fix must be deployed to production within 4 hours

---

## Solution Design

**Option A — Disable retry on payment endpoint:**
Quick fix. Doesn't solve the atomicity problem between payment and order record.

**Option B — Stripe Idempotency-Key + outbox pattern + webhook dedup (recommended):**
Use a stable per-order `Idempotency-Key` (order ID) so Stripe deduplicates on their side. Use transactional outbox so the order record write and payment event are atomic. Deduplicate incoming Stripe webhooks by event ID in Redis.

**Why Option B:**
- `Idempotency-Key` = order ID: any number of retries, Stripe only charges once
- Outbox: even if pod crashes after payment succeeds, the order record is atomically written in the same DB transaction as the outbox event
- Webhook dedup: Stripe guarantees at-least-once delivery — Redis dedup prevents double processing

```
POST /orders/{id}/pay
    │
    ├── BEGIN TRANSACTION
    │     ├── Write order record (Status: PaymentInitiated)
    │     └── Write outbox event (PaymentInitiated)
    └── COMMIT
         │
         ▼
    OutboxPublisher picks up event
         │
         ▼
    Stripe.PaymentIntents.Create
         Idempotency-Key: order-{orderId}  ← Stripe deduplicates here
         │
    PaymentIntent.Succeeded → update order
         │
         ▼
    Stripe webhook: payment_intent.succeeded
         │ Check Redis: "stripe-event:{eventId}" → EXISTS? skip : process + SET
         ▼
    Order marked Confirmed
```

---

## Implementation Tasks

1. **Add Stripe Idempotency-Key to PaymentIntent.Create**
   - Key format: `order-{orderId}` — stable, derived from business entity, not a random UUID
   - Set via `RequestOptions { IdempotencyKey = $"order-{orderId}" }`
   - Acceptance: Call `PaymentIntents.Create` twice with same orderId → Stripe returns same PaymentIntentId both times (verify in Stripe logs)

2. **Filter Polly retry to exclude payment creation**
   - Change retry policy: retry only on `HttpRequestException` with status 5xx or `TaskCanceledException`
   - Explicitly exclude retrying payment creation POST — use per-endpoint policy via `IHttpClientFactory` named clients
   - Acceptance: Timeout on payment endpoint → no retry (verify with Wiremock)

3. **Implement transactional outbox for payment initiation**
   - `BEGIN TRANSACTION` → write order record + outbox event → `COMMIT`
   - `OutboxPublisher` background service: polls outbox table, publishes events, marks as published
   - Acceptance: Kill pod after COMMIT but before Stripe call — on restart, outbox publisher completes the Stripe call; order not stuck in `PaymentInitiated`

4. **Idempotent Stripe webhook handler**
   - On `payment_intent.succeeded` webhook: check `Redis.SetAsync("stripe-event:{eventId}", "1", expiry: 24h)`
   - If key already exists → return 200 immediately (already processed)
   - Acceptance: Send same webhook event twice → order updated once (verify order.Status in DB)

5. **Stripe HMAC webhook signature verification**
   - `StripeClient.ConstructEvent(payload, sigHeader, webhookSecret)`
   - Use `FixedTimeEquals` for HMAC comparison — prevent timing attacks
   - Return 400 on invalid signature; log attempted payload for security audit
   - Acceptance: Invalid signature → 400; valid signature → processed

6. **Write integration test reproducing the original bug and verifying the fix**
   - Test: mock Stripe to return timeout on first call, success on second → verify single PaymentIntent created (idempotency key prevents duplicate)
   - Test: send `payment_intent.succeeded` webhook twice → verify order updated once
   - Acceptance: Both tests pass

---

## Acceptance Criteria

- [ ] Double PaymentIntent creation impossible: same `Idempotency-Key` → Stripe returns same PaymentIntentId (integration test)
- [ ] Polly retry on timeout does not retry payment creation (Wiremock test)
- [ ] Pod crash after DB commit: outbox publisher completes payment call on restart
- [ ] Duplicate webhook event: order updated once (Redis dedup integration test)
- [ ] Invalid Stripe signature: 400 returned (not 500); payload logged
- [ ] No regression on other endpoints that legitimately use retry

---

## Interview Talking Points

**Situation:** 12 customers double-charged after an AWS network blip caused HTTP timeouts. The API retried the Stripe payment creation, creating a second PaymentIntent. £40k in refunds, FCA review risk.

**Task:** Identify all root causes and implement a fix that makes the payment flow safe to retry.

**Action:**
- Added `Idempotency-Key: order-{orderId}` to every Stripe PaymentIntent creation — Stripe deduplicates on their side so any number of retries produces exactly one charge
- Implemented transactional outbox for the payment initiation event — the order record write and the event are committed in the same DB transaction, so a pod crash can never leave the order in a limbo state where payment succeeded but the record wasn't updated
- Added Redis-based webhook deduplication by Stripe event ID — since Stripe guarantees at-least-once delivery, this prevents the same webhook from being processed twice

**Result:** Zero double charges in the 6 months after the fix. Outbox pattern also caught 3 cases where the pod crashed mid-flow — all resolved automatically without customer impact.

**Follow-up questions to prepare:**
- "The idempotency key is `order-{orderId}`. What if the same customer places the order twice?" → Each order gets a new `orderId` — the key is order-scoped, not customer-scoped. A new order = new orderId = new payment.
- "What if the outbox publisher itself crashes after calling Stripe but before marking the event as published?" → Stripe's idempotency key prevents duplicate charges on the retry. The outbox entry is re-picked and the Stripe call is retried with the same key — Stripe returns the existing PaymentIntent.

---

## Key Concepts

`Stripe Idempotency-Key` · `Transactional outbox` · `Polly retry filtering` · `Redis idempotency dedup` · `FixedTimeEquals` · `Stripe HMAC webhook verification` · `At-least-once delivery`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
