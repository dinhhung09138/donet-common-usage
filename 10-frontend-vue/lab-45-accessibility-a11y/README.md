# Lab: Accessibility (a11y) Fundamentals (Vue)

## Objectives

- Audit and fix keyboard-only navigability across a full user flow
- Apply correct semantic HTML and ARIA roles instead of div-soup with click handlers
- Ensure focus management is correct for dynamic content (modals, route changes, toasts)
- Pass an automated accessibility audit (axe) with zero critical/serious violations

## Key Concepts

`semantic HTML first` · `ARIA roles/labels` · `focus management on route change` · `axe-core audit` · `keyboard-only walkthrough`

## Tasks

- [ ] Walk through the CRUD-form flow using only the keyboard (Tab/Shift+Tab/Enter/Space/Escape) and log every dead end
- [ ] Fix each dead end: replace non-semantic clickable `div`s with `button`/`a`, add missing `aria-label`s
- [ ] Move focus to the main heading (or an announced region) on every route change
- [ ] Verify modal and toast focus management (already built in earlier labs) meets WCAG focus-order expectations
- [ ] Run `axe-core` (browser extension or `vitest-axe`) against 3 key screens and fix all critical/serious findings
- [ ] Document remaining known limitations and a remediation plan for anything not fixed

## Expected Output

Three key screens pass an axe-core audit with zero critical/serious violations, and the CRUD flow is fully completable using only a keyboard.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
