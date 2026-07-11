# Lab: Code Splitting & Lazy Loading (Vue)

## Objectives

- Split the app bundle by route so initial load only ships what's needed
- Lazy-load heavy, rarely-used components (e.g. a chart library, a rich text editor)
- Prefetch likely-next routes to hide lazy-load latency
- Measure and document the bundle-size impact of each split

## Key Concepts

`defineAsyncComponent` · `Suspense fallback` · `dynamic import()` · `route-based code splitting` · `prefetch on hover` · `bundle analyzer`

## Tasks

- [ ] Convert each top-level route to `defineAsyncComponent` (or router-level lazy import) with a loading state
- [ ] Lazy-load one heavy component (e.g. a chart or rich-text editor) only used on one screen
- [ ] Add prefetch-on-hover for the nav link of a lazy route to hide load latency
- [ ] Run a bundle analyzer before/after and document the initial-bundle size reduction
- [ ] Verify a slow-3G network throttle still shows a reasonable loading fallback, not a blank screen
- [ ] Add error handling around lazy-loaded chunks to handle a failed dynamic import (e.g. after a deploy)

## Expected Output

A measured, documented reduction in initial bundle size from route/component-level code splitting, with graceful handling of a simulated failed chunk load.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
