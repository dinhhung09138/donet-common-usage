# Lab: Retry Pattern

## Objectives
- Implement transient-fault retry logic with exponential backoff and jitter for a network call.
- Distinguish retryable vs. non-retryable failures (5xx/timeouts vs. 4xx) and configure policy accordingly.
- Combine retry safely with circuit breaker and timeout to avoid amplifying downstream load during an outage.
- Reason about idempotency requirements for safely retrying non-idempotent operations (e.g., payments).

## Key Concepts
`Retry Pattern` · `Exponential Backoff` · `Jitter` · `Polly` · `Idempotency` · `Transient Fault Handling`

## Tasks
- [ ] Build a client call to a downstream endpoint that intermittently returns transient errors (500/timeout) vs. permanent errors (400/404).
- [ ] Configure a Polly retry policy with exponential backoff + jitter, retrying only on transient failures.
- [ ] Add an idempotency key to a POST request and verify duplicate retries don't double-process on the server side.
- [ ] Combine retry with a circuit breaker via `PolicyWrap` and verify retries stop once the breaker opens.
- [ ] Log each retry attempt with attempt number and delay.

## Expected Output
A test run showing the client retrying only transient failures with increasing backoff delays, no retries on permanent failures, and no duplicate side effects when retrying an idempotency-key-protected POST.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
