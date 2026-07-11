# Lab: Bulkhead Pattern

## Objectives
- Isolate resource pools (thread pool, connection pool) per downstream dependency so one failing dependency can't exhaust resources needed by others.
- Implement bulkhead isolation using Polly's bulkhead policy (concurrency limiter) or `SemaphoreSlim`.
- Demonstrate the failure mode bulkheads prevent: one slow dependency starving requests to a healthy dependency.
- Tune bulkhead limits based on expected concurrency and downstream capacity.

## Key Concepts
`Bulkhead Pattern` · `Resource Isolation` · `Polly Bulkhead` · `Concurrency Limiting` · `Thread Pool Starvation`

## Tasks
- [ ] Build a service that calls two independent downstreams (A: fast/healthy, B: slow/degraded) without isolation and reproduce B starving requests to A under load.
- [ ] Add a Polly bulkhead policy (or `SemaphoreSlim`) with a separate concurrency limit per downstream.
- [ ] Re-run the same load test and verify calls to A remain fast/healthy while B saturates and starts rejecting excess requests.
- [ ] Add a queue depth limit and return a fast-fail response (e.g., 503) when the bulkhead is full instead of queuing indefinitely.
- [ ] Capture before/after latency metrics for dependency A.

## Expected Output
A load test report/log comparing dependency A's latency with and without bulkhead isolation, showing A stays healthy even while B is saturated once bulkheads are applied.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
