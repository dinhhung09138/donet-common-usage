# Lab: Multi-Step Wizard Form (Vue)

## Objectives

- Build a multi-step form wizard with per-step validation gating progression
- Persist wizard state across steps (and across a page refresh) until final submit
- Support back-navigation without losing previously entered data
- Provide a review/summary step before final submission

## Key Concepts

`wizard state machine` · `step validation gate` · `persisted draft (localStorage/sessionStorage)` · `summary/review step`

## Tasks

- [ ] Model wizard steps as an explicit state machine (`currentStep`, `visitedSteps`)
- [ ] Validate the current step's fields before allowing `Next`
- [ ] Persist the in-progress draft to `sessionStorage` and restore it on refresh
- [ ] Allow `Back` navigation without clearing already-entered data in later steps
- [ ] Build a final review step summarizing all entered data with per-section 'Edit' links
- [ ] Clear the persisted draft only after a successful final submit

## Expected Output

A 4+ step wizard that survives a page refresh mid-flow, blocks step progression on invalid data, and ends in an accurate review-and-submit step.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
