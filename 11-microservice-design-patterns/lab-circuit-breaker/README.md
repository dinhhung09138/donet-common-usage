# Lab: Circuit Breaker Pattern

## Objectives
- Implement the Circuit Breaker pattern to prevent cascading failures when a downstream dependency becomes slow or unavailable.
- Use Polly to configure the closed/open/half-open state machine with failure thresholds and break duration.
- Combine circuit breaker with retry and timeout policies (Polly `PolicyWrap`) without creating retry storms.
- Instrument circuit state transitions for observability (logs/metrics) so on-call engineers can see when a breaker trips.

## Key Concepts
`Circuit Breaker` · `Polly` · `Resilience Policies` · `Fallback` · `Half-Open State` · `Bulkhead`

## Tasks
- [ ] Build a client service that calls a downstream API that can be forced to fail/slow down on demand.
- [ ] Configure a Polly circuit breaker policy (failure threshold, break duration) around the downstream call.
- [ ] Add a fallback response returned while the circuit is open.
- [ ] Combine the circuit breaker with a timeout and retry policy using `PolicyWrap`, ordered correctly to avoid amplifying failures.
- [ ] Emit state-transition events (closed → open → half-open) to logs/metrics.
- [ ] Load-test the downstream failure scenario and verify the breaker trips and recovers as configured.

## Expected Output
Logs/metrics showing the circuit breaker moving through closed → open → half-open → closed while the downstream service is forced to fail and then recover, with fallback responses served while open.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
