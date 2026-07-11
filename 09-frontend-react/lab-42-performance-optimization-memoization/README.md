# Lab: Performance Optimization & Memoization (React)

## Objectives

- Profile a real component tree to find unnecessary re-renders before optimizing blindly
- Apply memoization correctly (and know when it makes things worse)
- Optimize an expensive derived computation with proper caching
- Reduce layout thrash from unbatched DOM reads/writes

## Key Concepts

`React DevTools Profiler` · `React.memo` · `useMemo/useCallback` · `why-did-you-render style debugging` · `layout thrashing`

## Tasks

- [ ] Profile a moderately complex screen with React DevTools Profiler and identify the 2 costliest re-renders
- [ ] Fix one with `React.memo` + stable props (via `useCallback`/`useMemo`), proving the re-render count drops
- [ ] Deliberately over-memoize a cheap component and show it made things worse (extra comparison overhead)
- [ ] Move an expensive derived computation into `useMemo` with correct dependency tracking
- [ ] Identify and fix one instance of layout thrashing (interleaved DOM read/write in a loop)
- [ ] Write a before/after profiler screenshot comparison in the README

## Expected Output

A documented before/after profiling comparison showing a measured re-render or computation-cost reduction, plus one honest example of a memoization that backfired.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
