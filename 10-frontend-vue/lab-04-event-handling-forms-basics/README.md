# Lab: Event Handling & Basic Forms (Vue)

## Objectives

- Handle DOM events idiomatically (synthetic events vs native, event modifiers)
- Build a controlled form (text, select, checkbox, radio) with two-way binding
- Implement basic client-side validation and disable submit until the form is valid
- Handle async submit with pending/success/error UI states

## Key Concepts

`v-model` · `event modifiers (.prevent/.stop)` · `two-way binding` · `controlled inputs` · `form state object` · `submit pending state`

## Tasks

- [ ] Build a controlled form with text input, select, checkbox, and radio group using `v-model`
- [ ] Bind every field to a single reactive form-state object (not separate `ref`s per field)
- [ ] Implement `@submit.prevent` with basic required/format validation
- [ ] Disable the submit button while the form is invalid or a submission is pending
- [ ] Simulate an async submit (fake API call) and show pending/success/error states
- [ ] Reset the form correctly after a successful submit

## Expected Output

A form that blocks invalid submission, shows a pending state during a simulated network call, and resets cleanly on success.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
