# Lab: Cross-Component State Sharing (Vue)

## Objectives

- Use Context/provide-inject correctly for cross-cutting concerns (theme, auth, locale)
- Avoid the Context re-render trap by splitting state and dispatch providers
- Compare Context/provide-inject vs a global store and justify the choice per use case
- Build a typed, testable provider with a matching consumer hook/composable

## Key Concepts

`provide/inject` · `injection keys (InjectionKey<T>)` · `reactive provide pitfalls` · `composable wrapper for inject` · `readonly provided state`

## Tasks

- [ ] Build a typed `themeKey: InjectionKey<ThemeContext>` and provide it from the app root
- [ ] Build a `useTheme()` composable wrapping `inject(themeKey)` that throws if used outside the provider
- [ ] Provide a `readonly()` wrapped state so consumers can't mutate it directly, only via exposed methods
- [ ] Build an `AuthContext`-equivalent (`provide('auth', ...)`) exposing `user`, `login`, `logout`
- [ ] Write a short comparison note: when you'd reach for provide/inject vs Pinia
- [ ] Add a test that renders a consumer without providing the key and asserts the thrown error

## Expected Output

A theme and auth context/provide pair consumed by multiple components, with a documented, reproduced-and-fixed re-render issue.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
