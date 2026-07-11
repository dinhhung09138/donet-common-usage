# Lab: Dynamic Form Builder (Vue)

## Objectives

- Render a form entirely from a JSON schema instead of hardcoded JSX/template markup
- Support conditional field visibility driven by other field values
- Support at least 5 field types (text, number, select, checkbox, date) via a component registry
- Validate the schema-driven form using rules embedded in the schema itself

## Key Concepts

`schema-driven UI` · `field component registry (dynamic component)` · `conditional field logic` · `dynamic Zod schema generation`

## Tasks

- [ ] Define a JSON field-schema format (`type, name, label, validation, visibleIf`)
- [ ] Build a field-component registry using `<component :is="...">` mapping `type` to the right input
- [ ] Implement `visibleIf` conditional rendering (e.g. show 'Company Name' only if 'Type' === 'Business')
- [ ] Generate a Zod schema dynamically from the field-schema for validation
- [ ] Render two structurally different forms from two different JSON schemas with the same renderer
- [ ] Add a minimal schema editor (JSON textarea) that live-updates the rendered form

## Expected Output

A single form renderer that produces two different, fully validated forms purely from two different JSON schema inputs.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
