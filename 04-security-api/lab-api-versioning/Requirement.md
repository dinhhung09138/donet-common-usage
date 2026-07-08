# Lab: API Versioning Strategies

## Objectives

- Implement the same API with 3 versioning strategies
- Understand trade-offs of each approach
- Implement version deprecation and sunset headers

## Tasks

- [ ] Add `Asp.Versioning.Http` package
- [ ] Implement Strategy 1: **URL path versioning** (`/api/v1/orders`, `/api/v2/orders`)
- [ ] Implement Strategy 2: **Request header versioning** (`api-version: 2.0`)
- [ ] Implement Strategy 3: **Query string versioning** (`?api-version=2.0`)
- [ ] V1 and V2 have different response shapes (V2 adds fields, renames one)
- [ ] Implement default version fallback (if no version specified → V1)
- [ ] Add deprecation warning header for V1 (`Sunset: <date>`, `Deprecation: true`)
- [ ] Document all versions in Swagger UI (version selector)

## Expected Output

Same resource accessible via 3 versioning strategies. V1 returns deprecation headers. Swagger shows both versions.

## Key Concepts Practiced

`API versioning` · `Backward compatibility` · `Sunset header` · `Swagger multi-version` · `Breaking changes`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
