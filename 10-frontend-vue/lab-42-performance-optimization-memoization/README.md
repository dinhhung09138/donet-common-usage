# Lab: Performance Optimization & Memoization (Vue)

## Objectives

- Profile a real component tree to find unnecessary re-renders before optimizing blindly
- Apply memoization correctly (and know when it makes things worse)
- Optimize an expensive derived computation with proper caching
- Reduce layout thrash from unbatched DOM reads/writes

## Key Concepts

`Vue DevTools Performance tab` · `computed caching` · `shallowRef/markRaw` · `v-once/v-memo` · `layout thrashing`

## Tasks

- [ ] Profile a moderately complex screen with Vue DevTools and identify the 2 costliest re-renders
- [ ] Fix one with `computed`/`shallowRef` and proper key usage, proving the re-render count drops
- [ ] Deliberately misuse `v-memo` and show it made things worse or produced a stale-render bug
- [ ] Move an expensive derived computation into a properly-cached `computed`
- [ ] Identify and fix one instance of layout thrashing (interleaved DOM read/write in a loop)
- [ ] Write a before/after profiler screenshot comparison in the README

## Expected Output

A documented before/after profiling comparison showing a measured re-render or computation-cost reduction, plus one honest example of a memoization that backfired.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
