# Lab: Middleware Pipeline

## Objectives

- Understand ASP.NET Core request pipeline execution order
- Build reusable custom middleware components
- Implement cross-cutting concerns without coupling to business logic

## Tasks

- [ ] Create custom request logging middleware (log method, path, status code, duration)
- [ ] Create API key authentication middleware (short-circuit on missing/invalid key)
- [ ] Create rate limiting middleware (in-memory, fixed window per IP)
- [ ] Create response compression middleware wrapper
- [ ] Create global exception handling middleware (return RFC 7807 ProblemDetails)
- [ ] Demonstrate: what happens when you reorder middleware?
- [ ] Write unit tests for each middleware in isolation

## Expected Output

API with 5 middleware components chained. README explains the order and why it matters.

## Key Concepts Practiced

`Middleware` · `Pipeline order` · `Short-circuit` · `DI in middleware` · `ProblemDetails`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
