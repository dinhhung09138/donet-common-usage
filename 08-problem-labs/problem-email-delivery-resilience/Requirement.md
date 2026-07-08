# Problem Lab: Email Delivery Resilience — SendGrid Outage with Fallback

> **Category:** Integration Problem
> **Effort:** 2 days
> **Technologies:** IEmailSender abstraction, Polly circuit breaker, SendGrid → MailKit SMTP fallback, Hangfire retry + dead-letter, Azure Queue Storage durable buffer, IOptionsMonitor<T>

---

## Scenario

SendGrid has a 3-hour regional outage during a critical SaaS marketing campaign (50,000 emails queued). More critically, transactional emails — password resets, order confirmations, invoice notifications — are not being delivered. The engineering team has no fallback. Every email silently fails. Customers are locked out because password reset emails don't arrive.

**Business impact:** 200+ support tickets in 3 hours ("I can't reset my password"). Contractual SLA breach for invoice delivery (required within 1 hour of issuance by contract). Potential customer churn if the issue isn't resolved within the SLA window.

---

## The Problem

**Symptoms:**
- SendGrid API returning 503 for all send attempts
- Application logs: `SendGrid returned 503 after 3 retries — email dropped`
- No retry queue, no fallback — emails silently lost
- No health dashboard for email provider status

**Root cause analysis:**
- Single point of failure: only one email provider configured
- No circuit breaker — app retries endlessly during full outage, wasting threads
- No durable buffer — if email creation occurs in the HTTP request thread and fails, the email is lost entirely
- Transactional and marketing emails use the same pipeline — a marketing send causing rate limits blocks password reset emails

**Constraints:**
- Must not change the external email API (`IEmailSender` interface) for callers
- Transactional emails (password reset, order confirm) must have higher priority than marketing emails
- SMTP fallback credentials must never be stored in code or appsettings.json

---

## Solution Design

**Option A — Retry SendGrid indefinitely:**
Doesn't help during a full outage. Thread-blocking. Emails still lost if process restarts.

**Option B — Circuit breaker per provider + SMTP fallback + durable queue (recommended):**
`PrimaryEmailSender` (SendGrid) with circuit breaker. On open circuit: route to `FallbackEmailSender` (MailKit SMTP). All emails buffered in Azure Queue Storage before sending — durable across pod restarts. Priority queue: `transactional` vs `marketing` — separate queues with different concurrency limits.

**Why Option B:**
- Circuit breaker prevents thread pile-up during full outage — fails fast, routes to fallback
- Azure Queue Storage durability — emails survive pod restart, deployment, or crash
- Separate queues for transactional vs marketing — password resets never blocked by 50k marketing emails
- `IEmailSender` interface unchanged — zero impact on callers

```
Caller → IEmailSender.SendAsync(message, priority: Transactional)
              │
              ▼
         Azure Queue Storage (transactional-email-queue)
              │
              ▼
         EmailDispatchWorker (BackgroundService)
              │
              ├──► PrimaryEmailSender (SendGrid)
              │         Polly circuit breaker (5 failures in 30s → open for 60s)
              │         OPEN ──► FallbackEmailSender (MailKit SMTP)
              │
              └── Dead-letter after 3 provider-level failures (non-transient error)
```

---

## Implementation Tasks

1. **Define `IEmailSender` abstraction and `EmailMessage` DTO**
   - `SendAsync(EmailMessage message, EmailPriority priority, CancellationToken ct)`
   - `EmailPriority`: `Transactional`, `Marketing`
   - Acceptance: Existing callers compile without change after DI swap

2. **Implement `AzureQueueEmailBuffer` — enqueue before sending**
   - Serialize `EmailMessage` to JSON, enqueue to `transactional-email-queue` or `marketing-email-queue`
   - `IEmailSender` implementation: enqueue and return (< 10ms response to caller)
   - Acceptance: Email enqueued in Azure Queue Storage even if both providers are down

3. **Implement `SendGridEmailSender` with Polly circuit breaker**
   - Circuit breaker: 5 failures within 30 seconds → open for 60 seconds
   - Retry: 3 attempts with exponential backoff, retry on 429/503 only
   - Expose circuit state as `IHealthCheck` (`HealthStatus.Degraded` when half-open)
   - Acceptance: Wiremock returns 503 × 5 → circuit opens; subsequent calls fail-fast without hitting Wiremock

4. **Implement `MailKitSmtpEmailSender` as fallback**
   - SMTP credentials from Azure Key Vault (DefaultAzureCredential)
   - Acceptance: Send email via MailKit SMTP to Papercut (local dev) or MailHog

5. **Implement `EmailDispatchWorker : BackgroundService`**
   - Dequeue from `transactional-email-queue` first (priority), then `marketing-email-queue`
   - Try SendGrid → if circuit open or 503, try MailKit → if both fail, dead-letter with structured log
   - Concurrency: 10 workers for transactional, 2 workers for marketing
   - Acceptance: During simulated SendGrid outage, transactional emails delivered via MailKit within 30s

6. **Implement `IOptionsMonitor<T>` per-provider config**
   - `SendGridOptions`, `SmtpOptions` — reload without restart when Azure App Config changes
   - Acceptance: Change SMTP host in Azure App Config → workers pick up new config without restart

7. **Health check endpoint for email provider status**
   - `GET /health/ready` includes email circuit state: Healthy / Degraded / Unhealthy
   - Acceptance: Trigger circuit open → health check returns Degraded; circuit closes → returns Healthy

---

## Acceptance Criteria

- [ ] SendGrid 3-hour outage simulated (Wiremock): transactional emails delivered via SMTP fallback within 30s
- [ ] Circuit breaker opens after 5 failures in 30s; fails-fast during open state
- [ ] Email enqueued to Azure Queue survives pod restart — delivered after restart
- [ ] Marketing emails do not block transactional emails (separate queues + concurrency limits)
- [ ] Dead-letter: 3 provider failures → email in dead-letter queue with structured log
- [ ] SMTP credentials from Azure Key Vault (not appsettings.json)
- [ ] Health endpoint reflects current circuit state

---

## Interview Talking Points

**Situation:** SendGrid had a 3-hour outage. The platform had no fallback — transactional emails (password reset, invoice delivery) were silently dropped. 200+ support tickets within 3 hours.

**Task:** Design a resilient email delivery system that automatically falls back to SMTP when SendGrid is unavailable, with delivery guarantees and priority handling.

**Action:**
- Added Azure Queue Storage as a durable buffer before any send attempt — emails are now guaranteed to survive a pod restart, deployment, or provider outage
- Implemented Polly circuit breaker on the SendGrid client — after 5 failures in 30 seconds, the circuit opens and all calls route directly to the MailKit SMTP fallback without retrying SendGrid
- Used separate priority queues for transactional vs marketing emails with different worker concurrency — during a provider degradation, password resets complete in seconds while 50k marketing emails wait

**Result:** Zero email drops during the next SendGrid degradation event (45-minute partial outage 2 months later). All transactional emails delivered via SMTP fallback. Health endpoint alerted the on-call team within 30 seconds of circuit opening.

**Follow-up questions to prepare:**
- "What if both SendGrid and SMTP are down simultaneously?" → Email stays in Azure Queue Storage (durable). Dead-letter fires after 3 attempts. Ops alerted via Application Insights metric. When providers recover, remaining queue is processed automatically.
- "How do you prevent the marketing queue from starving during a partial SendGrid degradation?" → Two separate BackgroundService workers with independent concurrency limits. Transactional worker has 10x concurrency. Marketing worker is rate-limited independently of transactional.

---

## Key Concepts

`IEmailSender abstraction` · `Polly circuit breaker` · `SendGrid` · `MailKit SMTP` · `Azure Queue Storage` · `BackgroundService` · `Priority queue` · `IOptionsMonitor<T>` · `Azure Key Vault` · `IHealthCheck`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
