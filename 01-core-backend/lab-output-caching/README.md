# Lab: Output Caching

## Objectives
- Understand how Output Caching (.NET 7+) differs from Response Caching and IDistributedCache
- Configure cache policies with vary-by conditions (query string, header, route, user)
- Implement tag-based cache eviction to invalidate related entries on write operations
- Replace the default in-memory store with Redis for distributed output caching

## Key Concepts
`AddOutputCache` · `OutputCachePolicy` · `VaryByQuery` · `VaryByHeader` · `EvictByTag` · `IOutputCacheStore` · `Redis output cache` · `vs Response Caching` · `vs IDistributedCache`

## Tasks
- [ ] Install `Microsoft.AspNetCore.OutputCaching`; register `AddOutputCache()` and `UseOutputCache()` (note: order matters — after `UseRouting`)
- [ ] Define a `DefaultPolicy` (60s TTL) and a named `"products"` policy (300s TTL, vary by query string `category` and `page`)
- [ ] Apply `[OutputCache(PolicyName = "products")]` to the `GET /products` endpoint; verify cache HIT/MISS via `X-Cache` or custom response header
- [ ] Implement vary-by authenticated user: create a policy that includes the `sub` claim so each user gets their own cache entry
- [ ] Tag all product cache entries with `"products-tag"`; call `IOutputCacheStore.EvictByTagAsync("products-tag")` on `POST /products` to invalidate
- [ ] Replace in-memory store with Redis: install `Microsoft.AspNetCore.OutputCaching.StackExchangeRedis`; configure `AddOutputCache(o => o.AddRedisOutputCacheProvider(...))`
- [ ] Demonstrate the difference from `lab-caching-patterns`: write a side-by-side comparison showing OutputCache (declarative) vs cache-aside (manual) for the same endpoint
- [ ] Write integration tests asserting that the second identical request returns a cached response and that eviction invalidates the cache

## Expected Output
An API with Output Caching using named policies, vary-by-user, tag-based eviction, Redis store, and integration tests confirming cache hit and eviction behaviour.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
