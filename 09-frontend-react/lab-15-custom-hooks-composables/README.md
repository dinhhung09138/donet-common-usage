# Lab: Custom Hooks / Composables (React)

## Objectives

- Extract reusable stateful logic out of components into custom hooks/composables
- Design a hook/composable API that's easy to test in isolation from any component
- Build a `useFetch`/`useAsync`-style data hook with cancellation and caching-free re-fetch
- Compose multiple small hooks into one feature-level hook

## Key Concepts

`custom hooks` · `rules of hooks` · `useFetch pattern` · `hook composition` · `testing hooks (renderHook)`

## Tasks

- [ ] Extract a `useLocalStorage(key, initial)` hook with typed get/set
- [ ] Build a `useDebouncedValue(value, delay)` hook
- [ ] Build a `useFetch(url)` hook returning `{data, error, loading, refetch}` with abort-on-unmount
- [ ] Compose `useDebouncedValue` + `useFetch` into a `useSearch(query)` feature hook
- [ ] Write unit tests for each hook with `@testing-library/react`'s `renderHook`
- [ ] Document the Rules of Hooks violations you'd watch for in code review

## Expected Output

A small library of tested, independently reusable hooks/composables, culminating in one composed `useSearch` used by a real search UI.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
