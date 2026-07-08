# Problem Lab: 3rd-Party API Silent Breaking Change

> **Category:** Integration Problem
> **Effort:** 2 days
> **Technologies:** IHttpClientFactory typed client, NJsonSchema validation, Adapter pattern, PactNet consumer contract test, feature flag graceful disable, structured error logging

---

## Scenario

A credit scoring API provider silently changes their response schema in a version that was not supposed to be a breaking change. The field `creditScore` is renamed to `score`. 30% of loan applications start failing with `NullReferenceException` in production. The bug is not caught by the test suite because all HTTP clients are mocked with the old schema. The team learns about the issue from a customer complaint 4 hours later.

**Business impact:** 30% of loan applications rejected incorrectly for 4 hours. Legal obligation to manually review each affected application. FCA compliance risk (automated decision making error). Partner SLA breach with the credit bureau.

---

## The Problem

**Symptoms:**
- `NullReferenceException` on `response.CreditScore` — field is null after deserialization
- Root cause: provider returned `{ "score": 750 }` but code accessed `response.CreditScore`
- Mock tests passed (mocks use old schema); integration test against real API not in CI
- No schema validation at the HTTP boundary — deserialization errors are silent (null values, not exceptions)

**Root cause analysis:**
- HTTP client mocked with hardcoded old schema DTO — tests never call real provider
- No contract test verifying that the provider's actual response matches the expected schema
- No JSON schema validation at the API boundary — `System.Text.Json` silently ignores unknown fields and returns null for missing ones
- Adapter layer missing — domain code directly references the provider's DTO class, tightly coupled to provider schema

**Constraints:**
- Cannot change the credit bureau provider or force them to revert the change
- Must be able to disable the credit scoring integration instantly without a code deploy

---

## Solution Design

**Option A — Fix the field name and update the mock:**
Fixes the immediate bug. Does not prevent recurrence. Next time the provider changes a field, the same bug recurs.

**Option B — Adapter + JSON schema validation + PactNet contract test + feature flag (recommended):**
Adapter layer isolates domain from provider DTO. JSON schema validation at deserialization boundary catches schema drift immediately. PactNet consumer contract test runs against the provider's real API in CI. Feature flag allows instant graceful disable if the provider breaks again.

**Why Option B:**
- Adapter: provider schema changes break only the adapter, not domain code
- JSON schema validation: `NullReferenceException` replaced by explicit `SchemaValidationException` with field detail
- PactNet: contract test fails in CI before the breaking change reaches production
- Feature flag: 2-minute disable, not a hotfix deploy

```
Before fix:
  HTTP response → System.Text.Json deserialization → CreditScoringDto { CreditScore: null }
  Domain code: if (dto.CreditScore > 700) → NullReferenceException

After fix:
  HTTP response → JSON schema validation (NJsonSchema) → exception if schema invalid
               → deserialization → CreditScoringDto
               → Adapter.Map(dto) → CreditScoreResult (domain model)
  Domain code: uses CreditScoreResult, never knows DTO field names
```

---

## Implementation Tasks

1. **Implement Adapter pattern: isolate domain from provider DTO**
   - `CreditScoringDto` (provider-specific) vs `CreditScoreResult` (domain model)
   - `ICreditScoringAdapter.Map(CreditScoringDto dto) → CreditScoreResult`
   - Domain code only uses `CreditScoreResult` — zero direct references to `CreditScoringDto`
   - Acceptance: Architecture test (NetArchTest): domain layer has zero references to `CreditScoringDto`

2. **Add NJsonSchema validation at HTTP boundary**
   - Define JSON schema for expected provider response
   - Validate response body before deserialization: `schema.Validate(json)` → throw `ProviderSchemaException` with field details if invalid
   - Log: `{ ProviderName, ExpectedFields, ActualFields, ResponseSnippet }` for fast diagnosis
   - Acceptance: Send response with `score` instead of `creditScore` → `ProviderSchemaException` thrown with clear field diff, not `NullReferenceException`

3. **Implement PactNet consumer contract test**
   - Define Pact: consumer (loan app) expects `GET /credit-score/{customerId}` to return `{ "creditScore": number, "grade": string }`
   - Run `PactVerifier` against the real provider API in CI (or provider test server)
   - Acceptance: PactNet test fails in CI if provider changes `creditScore` to `score` → caught before deployment

4. **Add typed HTTP client with Polly resilience**
   - `ICreditScoringClient` with Refit interface
   - Polly: retry 2× on 503/429; circuit breaker (5 failures → open 60s); timeout 5s
   - Acceptance: Wiremock test: 503 × 2 → succeeds on 3rd; circuit opens after 5 failures

5. **Feature flag to disable credit scoring integration**
   - `[FeatureGate("CreditScoring")]` on the credit check endpoint
   - When disabled: return `CreditScoreResult.Unavailable` → loan application proceeds with manual review flag
   - Acceptance: Disable feature flag → endpoint returns 200 with `{ manualReviewRequired: true }` instead of calling provider

6. **Structured error logging for deserialization failures**
   - All `ProviderSchemaException` logged with: `{ ProviderName, CustomerId, SchemaVersion, ValidationErrors[] }`
   - Alert: Application Insights `TrackMetric("credit_scoring.schema_validation_failure_rate")` — alert if > 1% of calls
   - Acceptance: Simulated schema change → metric fires in Application Insights within 1 minute

---

## Acceptance Criteria

- [ ] Schema validation catches `score` vs `creditScore` mismatch before deserialization (unit test)
- [ ] Domain code has zero references to provider DTO (NetArchTest)
- [ ] PactNet contract test fails in CI if provider response schema changes (simulate with Pact provider mock)
- [ ] Feature flag disabled → endpoint returns manual review response (no provider call)
- [ ] Circuit breaker opens after 5 failures in 30s (Wiremock test)
- [ ] Schema validation failure logged with field diff and correlated request ID

---

## Interview Talking Points

**Situation:** A credit bureau changed `creditScore` to `score` in a non-breaking release. 30% of loan applications failed with NullReferenceException for 4 hours. Mocked tests all passed.

**Task:** Fix the immediate bug and design defenses that prevent the same class of problem from reaching production again.

**Action:**
- Added NJsonSchema validation at the HTTP response boundary — instead of a silent null from `System.Text.Json`, any field mismatch now throws a `ProviderSchemaException` with a clear diff of expected vs actual fields
- Introduced an Adapter layer between the provider DTO and domain model — a future field rename only breaks the adapter, not 15 domain classes that previously referenced the DTO directly
- Added a PactNet consumer contract test that runs against the provider's real test server in CI — the broken contract is now caught at the PR stage, before merge, not 4 hours into production

**Result:** Next breaking change from the same provider (field `grade` → `creditGrade` 3 months later) was caught by the PactNet test in CI within the provider's PR stage. Zero production impact.

**Follow-up questions to prepare:**
- "What if the provider doesn't support contract testing (no test server)?" → Use Pact's provider verification against a recorded response fixture (recorded from a real API call). Schema validation + structured logging is the fallback for providers who can't participate in contract testing.
- "Why is mocking the HTTP client in unit tests dangerous for this case?" → Mocks use the DTO you wrote, not the DTO the provider actually returns. Mocks test your code in isolation, not your integration assumptions. Contract tests specifically test the integration boundary.

---

## Key Concepts

`Adapter pattern` · `NJsonSchema validation` · `PactNet consumer contract test` · `Refit typed client` · `Polly circuit breaker` · `Feature flag graceful disable` · `IFeatureGate` · `NetArchTest` · `Structured error logging`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
