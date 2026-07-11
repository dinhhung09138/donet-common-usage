# Lab: Custom Hooks / Composables (Vue)

## Objectives

- Extract reusable stateful logic out of components into custom hooks/composables
- Design a hook/composable API that's easy to test in isolation from any component
- Build a `useFetch`/`useAsync`-style data hook with cancellation and caching-free re-fetch
- Compose multiple small hooks into one feature-level hook

## Key Concepts

`composables` · `reactivity rules in composables` · `useFetch pattern` · `composable composition` · `testing composables`

## Tasks

- [ ] Extract a `useLocalStorage(key, initial)` composable with typed get/set
- [ ] Build a `useDebouncedValue(value, delay)` composable
- [ ] Build a `useFetch(url)` composable returning `{data, error, loading, refetch}` with abort-on-unmount
- [ ] Compose `useDebouncedValue` + `useFetch` into a `useSearch(query)` feature composable
- [ ] Write unit tests for each composable with Vitest (mounting a throwaway test component)
- [ ] Document reactivity pitfalls (destructuring reactive objects losing reactivity) you'd watch for in code review

## Expected Output

A small library of tested, independently reusable hooks/composables, culminating in one composed `useSearch` used by a real search UI.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
