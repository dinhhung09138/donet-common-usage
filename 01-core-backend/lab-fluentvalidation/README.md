# Lab: FluentValidation

## Objectives
- Author `AbstractValidator<T>` classes that express complex, composable validation rules more maintainably than attribute-based validation, for use in production request/command validation.
- Integrate FluentValidation into the ASP.NET Core request pipeline (via `IValidator<T>` in a filter/middleware or MVC's automatic validation) so invalid requests are rejected consistently before reaching handlers.
- Implement conditional, cross-property, and asynchronous (e.g. DB-uniqueness-check) validation rules that Data Annotations cannot express cleanly.
- Compare FluentValidation against ASP.NET Core's built-in model validation and articulate when each is the right architectural choice.

## Key Concepts
`AbstractValidator<T>` · `RuleFor` · `When`/`Unless` · `MustAsync` · `RuleSet` · `IValidator<T>` · `ValidationResult` · Custom validators · ASP.NET Core pipeline integration (endpoint filter/`IEndpointFilter` or MVC filter)

## Tasks
- [ ] Define a request/command DTO (e.g. `CreateOrderRequest`) and author a `AbstractValidator<CreateOrderRequest>` covering required fields, length/range constraints, and at least one cross-property rule.
- [ ] Add a conditional rule using `When`/`Unless` (e.g. a discount code is required only when `IsPromotional == true`).
- [ ] Add an asynchronous rule using `MustAsync` that checks uniqueness against a repository/DbContext (e.g. email not already registered).
- [ ] Register validators in DI (`AddValidatorsFromAssembly`) and wire automatic validation into the ASP.NET Core pipeline for minimal API or MVC endpoints, returning a consistent `ProblemDetails` response on failure.
- [ ] Write unit tests for the validator directly (bypassing HTTP) covering both valid and invalid inputs, including the async rule.
- [ ] Write an integration test hitting the endpoint with an invalid payload and asserting a 400 response with the expected validation error shape.

## Expected Output
A working ASP.NET Core project where at least one endpoint is protected by a FluentValidation validator wired into the pipeline, unit tests covering synchronous, conditional, and asynchronous rules, and an integration test demonstrating a 400 `ProblemDetails` response for invalid input.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
