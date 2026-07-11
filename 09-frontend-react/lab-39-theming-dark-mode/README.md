# Lab: Theming & Dark Mode (React)

## Objectives

- Implement a design-token-based theme system supporting light/dark/system modes
- Persist the user's theme choice and respect `prefers-color-scheme` on first load
- Avoid a flash-of-wrong-theme on page load
- Verify color contrast meets WCAG AA in both themes

## Key Concepts

`CSS custom properties (design tokens)` · `ThemeContext/provider` · `prefers-color-scheme` · `no-flash theme boot script` · `WCAG AA contrast`

## Tasks

- [ ] Define a design-token set (colors, spacing) as CSS custom properties for light and dark themes
- [ ] Build a theme toggle (light/dark/system) persisted to `localStorage`
- [ ] Add a small inline boot script (before app hydration) that applies the stored theme to avoid a flash of the wrong theme
- [ ] Respect `prefers-color-scheme` when the user hasn't made an explicit choice
- [ ] Run an automated or manual contrast check on both themes' primary text/background pairs
- [ ] Verify every themed component (including third-party ones, e.g. charts) switches correctly

## Expected Output

A light/dark/system theme toggle with no flash-of-wrong-theme on reload, persisted preference, and documented WCAG AA contrast verification for both themes.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
