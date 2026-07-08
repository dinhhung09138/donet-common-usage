# lab-azure-api-management

## Objectives

- Import an existing ASP.NET Core API into Azure API Management via OpenAPI spec
- Configure inbound and outbound policies: JWT validation, rate limiting, header transformation
- Set up products and subscriptions to control API access
- Implement mock responses for APIs not yet deployed
- Version APIs in APIM and document deprecation

## Key Concepts

`APIM policy` · `inbound / outbound / backend / on-error` · `validate-jwt` · `rate-limit-by-key` · `set-header` · `mock-response` · `rewrite-uri` · `Product` · `Subscription key` · `Ocp-Apim-Subscription-Key` · `Developer portal` · `API versioning (path / header)` · `OpenAPI import` · `Named value` · `Backend`

## Tasks

- [ ] Provision an APIM instance (Developer tier) using Azure CLI or portal
- [ ] Import the Minimal API from `lab-minimal-api` into APIM via its OpenAPI (Swagger) JSON URL
- [ ] Add a `validate-jwt` inbound policy that validates the `Authorization` header against a known JWKS endpoint
- [ ] Add a `rate-limit-by-key` policy: 10 calls per 60 seconds per subscription key; return `429` with `Retry-After` header
- [ ] Add a `set-header` outbound policy that appends `X-Api-Version` and `X-Request-Id` to every response
- [ ] Create a Named Value to store a backend URL and reference it from a `set-backend-service` policy
- [ ] Add a `mock-response` policy for a not-yet-implemented endpoint — verify the mock is returned without hitting the backend
- [ ] Create two products: `Free` (10 req/min, no approval) and `Premium` (unlimited, requires approval); assign subscriptions
- [ ] Set up API versioning by path (`/v1/`, `/v2/`) with the v1 version marked as deprecated
- [ ] Test all policies via the APIM Developer Portal and the built-in test console

## Expected Output

A working APIM instance with at least one imported API, JWT validation, rate limiting, mock response, and two products — all verified via the developer portal and direct HTTP calls.
