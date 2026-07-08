# Lab: Rate Limiting Algorithms

## Objectives

- Implement token bucket and sliding window algorithms from scratch
- Compare with ASP.NET Core 7+ built-in rate limiting middleware
- Use Redis for distributed rate limiting across multiple instances

## Tasks

- [ ] Implement **token bucket** algorithm: fixed capacity, refill rate, burst allowed
- [ ] Implement **fixed window** algorithm: reset counter every N seconds
- [ ] Implement **sliding window** algorithm: rolling time window with Redis sorted set
- [ ] Implement **leaky bucket** algorithm: smooth output rate regardless of burst
- [ ] Add ASP.NET Core built-in rate limiting middleware (compare implementation)
- [ ] Implement per-user rate limiting (by API key or IP)
- [ ] Implement distributed rate limiting with Redis (works across multiple app instances)
- [ ] Return proper `429 Too Many Requests` with `Retry-After` header
- [ ] Write load test (NBomber or k6) showing rate limiting in action

## Expected Output

4 algorithm implementations. Redis-backed distributed version. Load test results in README.

## Key Concepts Practiced

`Token bucket` · `Sliding window` · `Redis` · `Distributed rate limiting` · `429 Retry-After`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
