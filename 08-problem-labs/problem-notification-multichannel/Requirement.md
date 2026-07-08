# Problem Lab: Multi-Channel Notification System

> **Category:** Feature Building
> **Effort:** 2–3 days
> **Technologies:** MassTransit + RabbitMQ, Channel\<T\>, SendGrid, SignalR, Hangfire, Redis, INotificationChannel abstraction

---

## Scenario

The product team needs a notification system that sends alerts through three channels: email (SendGrid), in-app real-time (SignalR), and future push notifications. Users can configure their channel preferences. Notifications must not be lost if a channel is temporarily unavailable — a failed email should retry, not silently drop.

**Business impact:** Without delivery guarantees, users miss critical alerts (order shipped, invoice due, password reset) — directly causing support tickets and churn.

---

## The Problem / Requirement

**Functional requirements:**
- Send notifications via email, in-app (SignalR), and extensible to push
- Per-user channel preferences stored and respected (e.g., user X: email only; user Y: email + in-app)
- At-least-once delivery: retry on transient failures
- Dead-letter after 3 failed attempts with structured log entry

**Non-functional requirements:**
- New channel types must be addable without changing dispatch logic (open/closed principle)
- Notification dispatch must not block the originating request
- Total dispatch latency visible via Application Insights custom metric

**Edge cases:**
- Channel preference store is unavailable — fall back to all channels
- SignalR user not connected — queue in-app notification for retrieval on next login
- SendGrid rate limit (429) — retry with exponential backoff, do not dead-letter on 429

---

## Solution Design

**Option A — Synchronous direct call:**
Call SendGrid + SignalR inline in the HTTP handler. Simple but blocks the request, no retry, one failure fails all channels.

**Option B — Message bus fan-out (recommended):**
Publish a `NotificationRequested` event to MassTransit. Independent consumers handle each channel. Retry and dead-letter handled per-consumer by MassTransit policy. Channel preferences fetched from Redis at consumer time.

**Why Option B:**
- Adding a new channel = new consumer, zero change to dispatch code
- Per-channel retry isolation: SendGrid failure doesn't affect SignalR delivery
- Async dispatch: HTTP request returns instantly after publishing

```
HTTP Handler
    │
    ▼
MassTransit Publish (NotificationRequested)
    │
    ├──► EmailNotificationConsumer ──► SendGrid (Polly retry on 429/5xx)
    │
    ├──► InAppNotificationConsumer ──► SignalR IHubContext (store if offline)
    │
    └──► [Future] PushNotificationConsumer ──► FCM / APNs
```

---

## Implementation Tasks

1. **Define `INotificationChannel` abstraction and `NotificationRequested` message**
   - Interface: `Task SendAsync(NotificationMessage message, CancellationToken ct)`
   - Message contains: UserId, Subject, Body, TemplateId (optional), CorrelationId
   - Acceptance: Unit test each consumer with a mock channel implementation

2. **Implement Redis-backed user channel preference store**
   - Key: `notif:prefs:{userId}` — value: JSON array of enabled channels
   - IOptionsMonitor for cache TTL config
   - Fallback: return all channels if Redis unavailable (catch and log)
   - Acceptance: Integration test with TestContainers Redis; verify fallback behavior

3. **Implement `EmailNotificationConsumer`**
   - Fetch preferences; skip if email not enabled for user
   - Send via SendGrid with dynamic template
   - UseMessageRetry: max 3, exponential (1s, 4s, 16s), retry on 429/5xx only
   - Dead-letter on permanent failure with structured log (UserId, TemplateId, error)
   - Acceptance: Test with Wiremock stub returning 429 then 200; verify retry count

4. **Implement `InAppNotificationConsumer`**
   - Use `IHubContext<NotificationHub>` to push to connected user group
   - If user not connected: persist notification to EF Core `PendingNotification` table
   - Expose GET `/notifications/pending` endpoint (cleared on retrieval)
   - Acceptance: Integration test with connected + disconnected user; verify persistence

5. **Wire MassTransit with RabbitMQ and configure dead-letter exchange**
   - `UseMessageRetry()` per consumer, `UseCircuitBreaker()` on EmailConsumer
   - Dead-letter exchange bound to `notification-dead-letter` queue
   - Acceptance: Force 3 failures; verify message lands in dead-letter queue

6. **Add Hangfire sweeper for stuck pending in-app notifications**
   - RecurringJob: every 5 minutes, re-attempt delivery for notifications older than 10 min
   - Acceptance: Simulate disconnected user for 15 min; verify sweeper delivers on reconnect

7. **Add Application Insights custom metric for dispatch latency per channel**
   - `TelemetryClient.TrackMetric("notification.dispatch.ms", elapsed, {"channel": "email"})`
   - Acceptance: Verify metric appears in App Insights after sending a test notification

---

## Acceptance Criteria

- [ ] Email notification delivered when user has email preference enabled
- [ ] Email retried 3× on 429 before dead-lettering (integration test with Wiremock)
- [ ] In-app notification stored in DB when user is offline; delivered on reconnect
- [ ] Adding a new channel requires only a new consumer class — zero changes to dispatch code (verified by architecture test)
- [ ] Channel preference store Redis failure falls back to all-channels (unit test)
- [ ] Dead-letter queue receives messages after exhausting retries (RabbitMQ management UI or integration test)
- [ ] All integration tests pass with TestContainers (RabbitMQ + PostgreSQL + Redis)

---

## Interview Talking Points

**Situation:** Product team needed a notification system that could send email and in-app alerts reliably, with user channel preferences and no silent drops.

**Task:** Design and implement the notification dispatch system, ensuring at-least-once delivery and extensibility for future channels.

**Action:**
- Published a `NotificationRequested` event via MassTransit instead of calling channels inline — this decoupled dispatch from the HTTP request and enabled per-channel retry isolation
- Used Redis for per-user channel preferences with a fall-back-to-all-channels strategy so a Redis outage wouldn't block notification delivery
- Stored in-app notifications in PostgreSQL for offline users and added a Hangfire sweeper to retry delivery — ensuring SignalR offline users still received alerts

**Result:** Zero notification drops in the first week after launch. Adding a new channel (push notifications) took 2 hours — one new consumer class, no changes to existing code.

**Follow-up questions to prepare:**
- "What if the same notification is delivered twice due to MassTransit retry?" → Idempotency key on NotificationRequested (UserId + TemplateId + CorrelationId hash)
- "How would you scale this to 100k notifications/minute?" → Partition RabbitMQ queues per channel; scale consumers independently; batch SendGrid API calls

---

## Key Concepts

`MassTransit` · `INotificationChannel` · `SendGrid` · `SignalR IHubContext` · `Redis` · `Hangfire` · `Dead-letter exchange` · `Channel<T>` · `IOptionsMonitor<T>`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
