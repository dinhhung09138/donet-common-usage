# lab-swagger-openapi

## Objectives

- Set up Swashbuckle.AspNetCore with full XML comment documentation
- Add JWT Bearer security scheme so testers can authenticate directly in Swagger UI
- Generate versioned Swagger documents matching the API versioning strategy
- Write custom IOperationFilter and ISchemaFilter for cross-cutting documentation needs

## Tasks

- [ ] Install and configure `Swashbuckle.AspNetCore`; enable XML comments from project properties
- [ ] Add `<InheritDocumentation>` and XML `<summary>` / `<remarks>` / `<response>` tags to all endpoints
- [ ] Register JWT Bearer security scheme (`SecuritySchemes` + `SecurityRequirements`) so the Authorize button appears
- [ ] Create an `IOperationFilter` that auto-appends a required `X-Correlation-ID` header to every operation
- [ ] Create an `ISchemaFilter` that marks value-type properties as non-nullable in generated schema
- [ ] Configure versioned Swagger docs: one `SwaggerDoc` per API version, filter by version with `IDocumentFilter`
- [ ] Set up ReDoc as an alternative UI at `/redoc`
- [ ] Expose the raw OpenAPI JSON at `/swagger/{version}/swagger.json` and verify it is valid
- [ ] Generate a typed C# client from the OpenAPI spec using NSwag CLI; confirm the client compiles
- [ ] Write integration test that fetches `/swagger/v1/swagger.json` and asserts it returns 200

## Expected Output

A running ASP.NET Core API with full Swagger UI at `/swagger`, versioned OpenAPI specs, a working Authorize button for JWT, and a generated NSwag client.

## Key Concepts Practiced

`Swashbuckle.AspNetCore` · `IOperationFilter` · `ISchemaFilter` · `SecurityRequirementsOperationFilter` · `XML comments` · `versioned Swagger` · `ReDoc` · `NSwag` · `OpenAPI spec`

## Status

- [ ] Lab completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/lab-swagger-openapi-pr.md`
