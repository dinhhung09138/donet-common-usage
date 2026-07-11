# Lab: Build Optimization & Deployment (React)

## Objectives

- Optimize the production build for size and cache efficiency (hashing, chunking strategy)
- Configure long-term-cacheable static asset headers and a safe cache-busting deploy
- Add build-time checks (type-check, lint, bundle-size budget) that fail CI on regression
- Deploy to a static host/CDN with correct SPA fallback routing

## Key Concepts

`Vite build config` · `content-hash filenames` · `manualChunks strategy` · `bundle-size budget in CI` · `SPA fallback (rewrite rule)`

## Tasks

- [ ] Configure `manualChunks` to split vendor code from app code for better long-term caching
- [ ] Verify built asset filenames are content-hashed and safe for aggressive `Cache-Control` headers
- [ ] Add a CI step that fails the build if the main bundle exceeds a defined size budget
- [ ] Add a CI step running type-check and lint as required gates before build
- [ ] Deploy the build to a static host/CDN with a SPA fallback rule (all routes → `index.html`)
- [ ] Verify a hard refresh on a deep route (e.g. `/items/42/edit`) works correctly post-deploy

## Expected Output

A CI pipeline that blocks on type/lint/bundle-size regressions, producing a cache-optimized build deployed to a static host where deep-link hard refresh works correctly.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
