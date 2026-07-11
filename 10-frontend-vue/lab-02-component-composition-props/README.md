# Lab: Component Composition & Props (Vue)

## Objectives

- Design components around single responsibility and explicit prop contracts
- Apply composition (slots/children) instead of prop-drilling flags for layout variants
- Type props strictly and document required vs optional inputs
- Build a small reusable UI kit (Button, Card, Badge) consumed by a feature screen

## Key Concepts

`props typing (defineProps)` · `slots (default/named/scoped)` · `component API design` · `default props` · `v-bind fallthrough attrs` · `presentational components`

## Tasks

- [ ] Build a `Button`, `Card`, and `Badge` component with `defineProps` + TypeScript types
- [ ] Use default and named slots so `Card` content is composed, not passed as a string prop
- [ ] Implement a scoped slot for a `List` component to let the parent customize item rendering
- [ ] Split a screen into presentational components vs a container that owns state/data
- [ ] Document each component's prop contract with JSDoc above `defineProps`
- [ ] Write a Storybook story or a manual demo page exercising every prop and slot variant

## Expected Output

A small reusable component library where every component has a typed, documented prop/slot API and is exercised by at least one live demo screen.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
