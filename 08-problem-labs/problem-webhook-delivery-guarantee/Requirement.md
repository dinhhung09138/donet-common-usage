# Problem Lab: Outgoing Webhook Delivery Guarantee

> **Category:** Integration Problem
> **Effort:** 2 days
> **Technologies:** Channel<T> retry queue, Polly exponential backoff, dead-letter, Azure Queue Storage, HMAC-SHA256 signing, EF Core delivery log, admin replay API

---

## Scenario

Your SaaS platform sends outgoing webhooks to subscriber endpoints when events occur (order created, invoice paid, user signed up). Subscriber endpoints are sometimes down or slow. The current implementation is fire-and-forget HTTP — if the subscriber returns 500 or times out, the webhook is silently dropped. 15% of webhooks never reach subscribers. One enterprise customer discovered missing webhooks during their quarterly audit and threatened to leave.

**Business impact:** Enterprise customer churn risk (missing webhooks broke their downstream automation). SLA violation (webhooks must be delivered within 5 minutes per contract). Support team spending 3 hours/week manually re-triggering missed webhooks.

---

## The Problem

**Symptoms:**
- 15% of outgoing webhooks return non-2xx or timeout — all silently dropped
- No visibility: no log of delivery attempts, no dashboard for subscribers
- Subscribers have no way to check if they missed webhooks
- No retry mechanism — transient subscriber downtime causes permanent data loss

**Root cause analysis:**
- `HttpClient.PostAsync()` called inline in event handler — fire-and-forget with no retry
- No durable buffer — if the pod restarts mid-send, in-flight webhooks are lost
- No HMAC signing — subscribers cannot verify payload authenticity
- No delivery log — cannot audit what was sent, when, and whether it succeeded

**Constraints:**
- Must not block the originating event handler (webhook delivery must be async)
- Subscribers define their own endpoint URL and secret — per-subscriber configuration
- Must support subscriber-initiated replay of failed webhooks

---

## Solution Design

**Option A — Synchronous retry in event handler:**
Blocks the caller. Retrying for 5 minutes would block the request thread. Not viable.

**Option B — Azure Queue Storage durable buffer + BackgroundService dispatcher + EF Core delivery log (recommended):**
Event handler enqueues webhook to Azure Queue Storage (durable, survives pod restart). `WebhookDispatchWorker` dequeues and dispatches with Polly retry. Delivery attempt logged to EF Core per attempt. Dead-letter after 3 failures. Admin API to replay dead-lettered webhooks.

**Why Option B:**
- Azure Queue Storage: durable across pod restart — webhook enqueued before pod crash is not lost
- Per-subscriber retry: each subscriber's endpoint has independent retry state
- Delivery log: full audit trail (subscriber, event, attempt count, response code, latency)
- Admin replay: operations can trigger re-delivery for any dead-lettered webhook

```
Event occurs in API
    │
    ▼
WebhookEventPublisher.Enqueue(event, subscriberId)
    │ ─── Azure Queue Storage (durable)
    ▼
WebhookDispatchWorker (BackgroundService)
    │ Dequeue message
    │ Build payload: { eventId, type, data, timestamp }
    │ Sign: X-Webhook-Signature: HMAC-SHA256(payload, subscriberSecret)
    │
    ├──► POST subscriber.callbackUrl
    │     2xx → mark Delivered, log attempt
    │     5xx/timeout → retry (Polly: 3×, exponential: 1s, 2s, 4s)
    │     After 3 failures → dead-letter (AzureQueue + EF Core DeliveryLog.Status=Failed)
    │
    └──► Admin: POST /admin/webhooks/{deliveryId}/replay
              Re-enqueue from dead-letter → dispatch again
```

---

## Implementation Tasks

1. **Design EF Core `WebhookDelivery` entity**
   - Fields: Id, SubscriberId, EventType, Payload (JSON), Status (Pending/Delivered/Failed), AttemptCount, LastAttemptAt, NextAttemptAt, ResponseCode, ResponseBody, CreatedAt
   - `WebhookSubscriber`: Id, CallbackUrl, Secret (hashed at rest), EventTypes (array), Active
   - Acceptance: EF Core migration creates both tables; seed 2 test subscribers

2. **Implement `WebhookEventPublisher` — enqueue to Azure Queue + write DeliveryLog**
   - Both operations in one EF Core transaction: write `WebhookDelivery` (Pending) + enqueue to Azure Queue Storage
   - Acceptance: Event published → `WebhookDelivery` record exists + message in Azure Queue

3. **Implement HMAC-SHA256 payload signing**
   - `X-Webhook-Signature: sha256=HMAC-SHA256(payload, subscriberSecret)`
   - Secret retrieved from Azure Key Vault per subscriber (not stored in DB in plaintext)
   - Include `X-Webhook-Timestamp` header for replay prevention
   - Acceptance: Subscriber-side verification test: valid payload → verified; tampered payload → rejected

4. **Implement `WebhookDispatchWorker : BackgroundService`**
   - Dequeue from Azure Queue with visibility timeout (2× estimated processing time)
   - HTTP POST to subscriber callback URL with signed payload
   - Polly retry: 3 attempts, exponential (1s, 2s, 4s), retry on 5xx and timeout
   - Update `WebhookDelivery.AttemptCount`, `Status`, `ResponseCode` on each attempt
   - Acceptance: Subscriber returns 503 twice then 200 → `Delivered` after 3rd attempt; AttemptCount = 3

5. **Dead-letter after max retries**
   - After 3 failures: move to Azure dead-letter queue, update `WebhookDelivery.Status = Failed`
   - Application Insights metric: `webhook.delivery.failed_rate` per subscriber
   - Acceptance: Subscriber returns 500 × 3 → dead-lettered; metric incremented

6. **Admin API: list failed deliveries + replay**
   - `GET /admin/webhooks/failed?subscriberId={id}` — paginated list of failed deliveries
   - `POST /admin/webhooks/{deliveryId}/replay` — re-enqueue from dead-letter
   - Authorization: `[Authorize(Roles = "Admin")]`
   - Acceptance: Dead-lettered delivery → call replay endpoint → delivery re-attempted; on success marked Delivered

7. **Subscriber-facing delivery history endpoint**
   - `GET /webhooks/deliveries?eventType=order.created&since=2024-01-01` — authenticated by subscriber API key
   - Returns: eventId, status, attemptCount, deliveredAt
   - Acceptance: Subscriber queries own delivery history; cannot see other subscribers' deliveries

---

## Acceptance Criteria

- [ ] Pod restart during dispatch: webhook not lost (Azure Queue durable, re-processed after restart)
- [ ] 3 consecutive 500s from subscriber → dead-lettered, `WebhookDelivery.Status = Failed`
- [ ] Subscriber 503 × 2 then 200 → delivered, AttemptCount = 3
- [ ] HMAC-SHA256 signed payload verifiable by subscriber (integration test with verification logic)
- [ ] Admin can replay failed webhook → delivery re-attempted
- [ ] Subscriber delivery history endpoint returns only own deliveries (isolation test)
- [ ] `webhook.delivery.failed_rate` metric visible in Application Insights

---

## Interview Talking Points

**Situation:** 15% of outgoing webhooks were silently dropped — fire-and-forget HTTP with no retry. Enterprise customer discovered missing webhooks during a quarterly audit and threatened to leave.

**Task:** Design a webhook delivery system with guaranteed at-least-once delivery, full audit trail, and subscriber-facing observability.

**Action:**
- Replaced fire-and-forget HTTP with Azure Queue Storage as a durable buffer — webhooks are enqueued atomically with the event record, surviving pod restarts and deployments
- Implemented Polly retry with exponential backoff per subscriber endpoint — transient downstream unavailability is now automatically recovered without manual intervention
- Added HMAC-SHA256 signing with per-subscriber secrets from Azure Key Vault, enabling subscribers to verify payload authenticity and detect tampering

**Result:** Webhook delivery rate improved from 85% to 99.7%. The enterprise customer withdrew the churn threat after reviewing the new delivery log dashboard. Support team's manual webhook re-triggering work dropped from 3 hours/week to zero.

**Follow-up questions to prepare:**
- "What if a subscriber's endpoint changes URL?" → `WebhookSubscriber` has an update endpoint (admin-authenticated). Active deliveries in-flight continue to the old URL; new deliveries use the new URL. Re-queuing in-flight deliveries to the new URL is a separate admin operation.
- "How do you prevent a slow subscriber from blocking delivery to other subscribers?" → `WebhookDispatchWorker` uses per-subscriber concurrency limits. Each subscriber's retry queue is isolated. A subscriber with a 30s endpoint timeout doesn't affect other subscribers.

---

## Key Concepts

`Azure Queue Storage` · `BackgroundService` · `Polly exponential backoff` · `Dead-letter queue` · `HMAC-SHA256 signing` · `EF Core audit log` · `Admin replay API` · `At-least-once delivery` · `Visibility timeout`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
