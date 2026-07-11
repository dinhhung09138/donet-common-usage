# Lab: Cross-Component State Sharing (React)

## Objectives

- Use Context/provide-inject correctly for cross-cutting concerns (theme, auth, locale)
- Avoid the Context re-render trap by splitting state and dispatch providers
- Compare Context/provide-inject vs a global store and justify the choice per use case
- Build a typed, testable provider with a matching consumer hook/composable

## Key Concepts

`createContext` · `Provider/Consumer` · `context re-render trap` · `split state/dispatch context` · `custom useX hook wrapper`

## Tasks

- [ ] Build a `ThemeContext` with a typed value and a `useTheme()` consumer hook that throws if used outside the provider
- [ ] Reproduce the Context re-render trap: every consumer re-renders on any state change
- [ ] Fix it by splitting into separate state and dispatch contexts (or memoizing the value)
- [ ] Build an `AuthContext` exposing `user`, `login`, `logout` consumed by 3+ components
- [ ] Write a short comparison note: when you'd reach for Context vs Redux/Zustand
- [ ] Add a test that renders a consumer without a provider and asserts the thrown error

## Expected Output

A theme and auth context/provide pair consumed by multiple components, with a documented, reproduced-and-fixed re-render issue.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
