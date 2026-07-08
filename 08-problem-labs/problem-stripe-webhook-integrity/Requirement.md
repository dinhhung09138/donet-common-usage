# Problem Lab: Stripe Webhook Integrity — Duplicate Processing and Replay Attacks

> **Category:** Integration Problem
> **Effort:** 1–2 days
> **Technologies:** Stripe ConstructEvent, HMAC-SHA256, FixedTimeEquals, Redis idempotency, replay attack prevention, out-of-order event handling

---

## Scenario

Production receives duplicate Stripe webhook events after a network retry. Subscriptions are activated twice, and payments are processed twice. Investigation reveals that Stripe signature verification was removed from the dev branch "to simplify testing" and the PR was merged to main 3 weeks ago. Any HTTP client can now forge webhook events.

**Business impact:** Double-activated subscriptions allow users to access Enterprise features on a Free plan. Double-processed payments cause duplicate charges. Stripe can send any event and the system will process it — including forged events from a malicious actor.

---

## The Problem

**Symptoms:**
- `payment_intent.succeeded` webhook processed 2× for the same payment — order confirmed twice, customer charged twice
- `customer.subscription.created` processed 2× — user granted Enterprise access twice (harmless but incorrect)
- No signature verification: any POST to `/webhooks/stripe` is accepted and processed

**Root cause analysis:**
- `StripeClient.ConstructEvent()` call was removed — payload processed without verifying HMAC-SHA256 signature
- No event deduplication — same `eventId` processed multiple times if Stripe retries delivery
- Stripe retries webhook delivery if it doesn't receive 200 within 30 seconds — on slow processing, the endpoint times out and Stripe retries
- Out-of-order events not handled: `payment_intent.payment_failed` arriving after `payment_intent.succeeded` overwrites the correct `Confirmed` status with `Failed`

**Constraints:**
- Must process Stripe webhooks asynchronously (30s timeout is too short for some events)
- Must handle out-of-order events correctly

---

## Solution Design

**Option A — Just re-add signature verification:**
Fixes forgery. Doesn't fix duplicate processing or out-of-order events.

**Option B — Signature verification + Redis event dedup + async processing with sequence ordering (recommended):**
Verify HMAC-SHA256 signature first (reject unsigned events). Deduplicate by `eventId` in Redis. Enqueue to MassTransit/Azure Queue for async processing (return 200 immediately). Apply event version/sequence to prevent out-of-order overwrites.

**Why Option B:**
- Signature verification: only Stripe can send events
- Redis dedup: Stripe's at-least-once delivery handled — same event processed exactly once
- Async processing: return 200 immediately, process in background — no timeout retriggers
- Sequence ordering: `UpdatedAt` optimistic concurrency prevents stale event overwrites

```
POST /webhooks/stripe
    │
    ├── 1. ConstructEvent() — verify HMAC-SHA256 signature
    │        Invalid → 400 Bad Request (log attempted payload)
    │
    ├── 2. Check Redis: "stripe:event:{eventId}" EXISTS → 200 (already processed, skip)
    │
    ├── 3. Enqueue to processing queue (return 200 immediately — avoids Stripe timeout retry)
    │
    └── Background processor:
            Redis SET "stripe:event:{eventId}" EX 86400 (24h dedup window)
            Process event by type
            Out-of-order guard: only update if event.CreatedAt > entity.LastStripeEventAt
```

---

## Implementation Tasks

1. **Restore Stripe HMAC-SHA256 signature verification**
   - `StripeClient.ConstructEvent(requestBody, stripeSignatureHeader, webhookSecret)`
   - Use `FixedTimeEquals` internally (Stripe SDK does this) — do not compare strings with `==`
   - Return 400 with structured log on invalid signature: `{ SourceIp, Path, SignatureHeader, Timestamp }`
   - Acceptance: Send valid webhook → 200. Send with invalid signature → 400. Send with no signature header → 400.

2. **Implement Redis event deduplication by Stripe eventId**
   - Before processing: `Redis.SetAsync("stripe:event:{eventId}", "1", expiry: 24h, when: NotExists)`
   - Returns `false` if key already exists → skip processing, return 200 (Stripe considers it delivered)
   - Acceptance: Send same eventId twice → processed once; second call returns 200 without processing

3. **Return 200 immediately + enqueue for async processing**
   - Endpoint: verify signature → dedup check → enqueue to Azure Queue Storage → return 200
   - Processing worker: `StripeWebhookProcessor : BackgroundService`
   - Acceptance: Endpoint responds in < 50ms (no synchronous Stripe API calls)

4. **Implement out-of-order event guard**
   - Track `LastStripeEventAt` timestamp per entity (Payment, Subscription)
   - Only apply event if `event.CreatedAt > entity.LastStripeEventAt`
   - Acceptance: Send `payment_intent.succeeded` (T=100), then `payment_intent.payment_failed` (T=50) → payment remains `Confirmed` (T=50 < T=100, older event ignored)

5. **Handle each Stripe event type with typed handlers**
   - `payment_intent.succeeded` → confirm order, update payment status
   - `payment_intent.payment_failed` → mark payment failed
   - `customer.subscription.created` → activate subscription tier
   - `customer.subscription.deleted` → downgrade to Free
   - Unknown event types → log and dead-letter (don't crash)
   - Acceptance: Integration test for each event type; unknown type logged + dead-lettered

6. **Replay attack prevention: timestamp window validation**
   - Check `Stripe-Signature` header timestamp: reject if `|now - eventTimestamp| > 300 seconds`
   - Acceptance: Send valid webhook with timestamp from 10 minutes ago → 400 rejected

---

## Acceptance Criteria

- [ ] Missing signature → 400; invalid signature → 400; valid signature → 200 (tests for each)
- [ ] Duplicate eventId → processed once; second request returns 200 (Redis dedup)
- [ ] Webhook processed within 30s (async, no Stripe retry triggered)
- [ ] Out-of-order event: older event does not overwrite newer state
- [ ] Timestamp > 5 minutes old → 400 (replay attack prevention)
- [ ] Unknown event type → dead-lettered, not crashed
- [ ] Integration tests: 5 event types × happy path + duplicate path

---

## Interview Talking Points

**Situation:** Stripe signature verification was removed in a dev branch and accidentally merged to main. Stripe was retrying events, causing duplicate processing. Any HTTP client could forge events.

**Task:** Re-secure the webhook endpoint and make it idempotent so duplicate delivery has no side effects.

**Action:**
- Restored `StripeClient.ConstructEvent()` with HMAC-SHA256 signature verification — invalid or missing signatures return 400 immediately with a security audit log entry
- Added Redis idempotency store keyed by Stripe's `eventId` — since Stripe guarantees at-least-once delivery, the same event is now processed exactly once regardless of how many times it arrives
- Made the endpoint return 200 immediately and process asynchronously via Azure Queue Storage — eliminating the Stripe 30-second timeout that was causing retry storms

**Result:** Zero duplicate subscription activations or double charges in the 4 months after the fix. The security audit log caught 3 forged webhook attempts from an automated scanner within the first week.

**Follow-up questions to prepare:**
- "What's the difference between HMAC-SHA256 and a shared secret password check?" → HMAC signs the entire payload, not just a header token. An attacker can't forge a valid signature without knowing the webhook secret, even if they intercept a real signed payload, because the signature is tied to that exact payload content.
- "What if the Redis dedup store goes down?" → Fail-open: process the event and accept the small risk of duplicate processing, rather than dropping events. For payments, the Stripe `Idempotency-Key` at the PaymentIntent level provides additional protection.

---

## Key Concepts

`Stripe ConstructEvent` · `HMAC-SHA256` · `FixedTimeEquals` · `Redis idempotency dedup` · `Replay attack prevention` · `Timestamp window validation` · `Async webhook processing` · `Out-of-order event guard` · `At-least-once delivery`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
