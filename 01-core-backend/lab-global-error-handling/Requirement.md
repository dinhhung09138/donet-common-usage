# lab-global-error-handling

## Objectives

- Build a consistent RFC 7807 error response across all API error types
- Use the .NET 8 IExceptionHandler interface instead of the older delegate-based approach
- Design a custom exception hierarchy that maps cleanly to HTTP status codes
- Distinguish between operational errors (4xx) and unexpected errors (500)

## Tasks

- [ ] Define a custom exception hierarchy: `AppException` base → `NotFoundException` (404), `ConflictException` (409), `ValidationException` (422), `ForbiddenException` (403)
- [ ] Implement `IExceptionHandler` (.NET 8): map each exception type to its HTTP status code and return RFC 7807 `ProblemDetails` JSON
- [ ] Register `AddProblemDetails()` and `AddExceptionHandler<GlobalExceptionHandler>()` in DI
- [ ] Configure `UseExceptionHandler()` to invoke the registered `IExceptionHandler`; ensure unhandled exceptions return 500 with no stack trace in production
- [ ] Extend `ProblemDetails` with custom `extensions` fields: `traceId`, `errorCode`, `timestamp`
- [ ] Return 422 + `ValidationProblemDetails` for FluentValidation failures; ensure `errors` dictionary matches format expected by frontend
- [ ] Write unit tests for `GlobalExceptionHandler` asserting status codes and response bodies
- [ ] Write integration tests confirming that thrown `NotFoundException` results in a 404 ProblemDetails response

## Expected Output

A global error handler that returns RFC 7807 ProblemDetails for all exception types, with correct status codes, no leaked stack traces, and passing unit + integration tests.

## Key Concepts Practiced

`IExceptionHandler` · `IProblemDetailsService` · `AddProblemDetails` · `RFC 7807` · `custom exception hierarchy` · `HTTP status mapping` · `422 vs 400` · `ProblemDetailsContext`

## Status

- [ ] Lab completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/lab-global-error-handling-pr.md`
