# Lab: ASP.NET Core Model Validation

## Objectives
- Apply built-in Data Annotation validation attributes to request models and understand how `ModelState`/automatic `[ApiController]` validation drives the 400 response pipeline.
- Implement a custom `ValidationAttribute` for a business rule not covered by built-in attributes, understanding the `IsValid` contract and error message formatting.
- Implement `IValidatableObject` for cross-property validation that a single attribute cannot express.
- Customize the automatic validation problem details response (`InvalidModelStateResponseFactory`) to match a consistent API error contract, as expected in a production API gateway/service boundary.

## Key Concepts
`[Required]`/`[Range]`/`[RegularExpression]`/`[EmailAddress]` · `ModelState` · `[ApiController]` automatic 400 · Custom `ValidationAttribute` · `IValidatableObject` · `InvalidModelStateResponseFactory` · `ProblemDetails`

## Tasks
- [ ] Define a request model annotated with built-in validation attributes covering required fields, ranges, and pattern matching.
- [ ] Confirm and demonstrate that `[ApiController]` triggers automatic model validation and returns a 400 `ValidationProblemDetails` response without explicit `ModelState.IsValid` checks in the action.
- [ ] Implement a custom `ValidationAttribute` (e.g. `[FutureDate]` or `[NotProfaneWord]`) enforcing a rule the built-in attributes can't express, with a clear error message.
- [ ] Implement `IValidatableObject` on a model to enforce a cross-property rule (e.g. `EndDate` must be after `StartDate`).
- [ ] Customize `InvalidModelStateResponseFactory` in `AddControllers`/`ConfigureApiBehaviorOptions` to shape validation error responses into a consistent API error contract (e.g. field-level error codes).
- [ ] Write integration tests posting valid and invalid payloads and asserting both the 400 status and the shape of the returned error body.

## Expected Output
A working ASP.NET Core API with a request model exercising built-in, custom, and cross-property (`IValidatableObject`) validation, a customized validation error response contract, and integration tests proving invalid requests return the expected structured error response.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
