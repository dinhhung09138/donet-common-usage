# Lab: Caching Patterns

## Objectives

- Implement in-memory cache with eviction policies
- Implement distributed Redis cache for multi-instance scenarios
- Apply cache-aside pattern correctly (read-through, write-invalidate)
- Handle cache stampede with locking

## Tasks

- [ ] Add `IMemoryCache` with size limits and sliding/absolute expiration
- [ ] Set up Redis locally with Docker Compose
- [ ] Add `IDistributedCache` with Redis provider
- [ ] Implement cache-aside pattern in a service layer
- [ ] Implement cache invalidation on write operations
- [ ] Demonstrate cache stampede scenario and fix with `SemaphoreSlim` locking
- [ ] Add cache hit/miss metrics via OpenTelemetry

## Expected Output

API that reads from cache-first, falls back to DB, invalidates on writes. Docker Compose file for Redis included.

## Key Concepts Practiced

`IMemoryCache` · `IDistributedCache` · `Redis` · `Cache-aside` · `Cache stampede`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
