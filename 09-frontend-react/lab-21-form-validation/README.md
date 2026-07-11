# Lab: Form Validation (React)

## Objectives

- Implement schema-based validation shared between client-side and (conceptually) server-side rules
- Show field-level errors on blur/submit without being intrusive on first render
- Handle cross-field validation (e.g. confirm password, date range)
- Surface server-side validation errors (422) back into the correct form fields

## Key Concepts

`React Hook Form` · `Zod schema` · `field-level error timing` · `cross-field refine` · `server error mapping`

## Tasks

- [ ] Set up React Hook Form with a Zod schema resolver for a registration form
- [ ] Configure validation mode so errors appear on blur/submit, not on every keystroke
- [ ] Add a cross-field rule (`.refine`) for password confirmation and a date-range field
- [ ] Simulate a 422 response with field-level errors and map them onto the correct form fields
- [ ] Add an async validator (e.g. 'username taken') debounced against a mock endpoint
- [ ] Write tests covering: empty submit, cross-field failure, and successful submit

## Expected Output

A registration form whose client validation, cross-field rules, and server-error mapping all funnel into the same field-level error UI.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
