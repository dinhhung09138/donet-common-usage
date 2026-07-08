# Capstone: AI Developer Portal

## Business Context

Build an API developer portal with: API key provisioning, interactive Swagger docs, an AI chat assistant that answers questions about your API using RAG, and outgoing webhook management with HMAC signing. This is a differentiator project that showcases AI tooling integration — highly relevant for 2026 UK/US hiring.

## Prerequisite Labs

- `lab-api-key-authentication`
- `lab-semantic-kernel-rag`
- `lab-webhook-patterns`
- `lab-mcp-server-dotnet`
- `lab-swagger-openapi`
- `lab-rate-limiting-aspnetcore`
- `lab-azure-blob-storage`

## Functional Requirements

- Developer self-service: register, generate API keys (hashed at rest), view usage stats
- Swagger UI with JWT + API Key auth schemes documented
- AI assistant: developer asks "How do I paginate the /orders endpoint?" — assistant answers using RAG over the API documentation
- Webhook subscriptions: developers register URLs + event types; system dispatches signed events; retry on failure
- API key revocation: immediate effect (no caching of revoked keys); grace-period rotation (old key valid 24h after new key issued)
- Usage stats: per-key request count, error rate, top endpoints — powered by Redis counters

## Non-Functional Requirements

- API key lookup: O(1) via key prefix lookup (first 8 chars stored unhashed for lookup, rest hashed with PBKDF2)
- AI chat: grounded strictly on indexed API docs (no hallucination about unsupported endpoints)
- Webhook dispatch: at-least-once delivery; Channel<T> retry queue; dead-letter after 5 failures
- Rate limiting per API key: configurable per plan (Free: 100 req/min, Pro: 1000 req/min)
- Timing-safe API key comparison: `CryptographicOperations.FixedTimeEquals`

## Architecture

```
API Key Auth:
  → DeveloperAuthenticationHandler reads X-Api-Key header
  → extract prefix (first 8 chars) → lookup ApiKey record by prefix
  → hash remaining chars with stored salt → FixedTimeEquals comparison
  → set claims (developerId, plan, tenantId)

AI Assistant POST /chat:
  → receive question
  → Semantic Kernel: retrieve top-5 docs from Azure AI Search (cosine similarity)
  → augment prompt with retrieved docs + "Only answer based on provided context"
  → stream response via IAsyncEnumerable

Webhook dispatch (background):
  → EventPublished → enqueue to Channel<WebhookJob>
  → for each subscriber matching event type:
      → HTTP POST to subscriber URL
      → sign payload with HMAC-SHA256 (subscriber secret)
      → on failure: exponential backoff retry (max 5 attempts)
      → dead-letter to Blob after 5 failures

RAG index population:
  → POST /admin/docs/reindex
  → read OpenAPI spec + custom docs from Blob
  → chunk into 500-token segments
  → embed with Azure OpenAI text-embedding-3-small
  → upsert into Azure AI Search index
```

## Implementation Steps

1. **API key schema:** `ApiKey` — `Prefix` (varchar 8, indexed), `HashedSecret` (byte[]), `Salt` (byte[]), `PlanId`, `DeveloperId`, `RevokedAt?`, `ExpiresAt?`
2. **Key generation:** `RandomNumberGenerator.GetBytes(32)` → prefix = Base64(first 6 bytes); hash remainder with PBKDF2 (100k iterations)
3. **AuthenticationHandler:** custom `AuthenticationHandler<ApiKeyAuthOptions>`; prefix lookup + `FixedTimeEquals` comparison; cache valid key identity for 60s (avoid PBKDF2 per request)
4. **Grace-period rotation:** when developer generates new key, old key `ExpiresAt` set to `now + 24h`; both valid during overlap
5. **Rate limiting:** `AddRateLimiter`, partition key = `DeveloperId` claim; limits from `IOptionsMonitor<PlanLimits>` keyed by plan name
6. **RAG pipeline:** load OpenAPI JSON from Azure Blob; parse paths into chunks; embed with `ITextEmbeddingGenerationService`; upsert to Azure AI Search
7. **Semantic Kernel chat:** `Kernel` with `IChatCompletionService` + `TextMemoryPlugin`; `SearchAsync` for top-5 docs; system prompt instructs model to cite doc section
8. **Webhook dispatcher:** `IWebhookDispatcher` backed by `Channel<WebhookJob>`; `BackgroundService` consumer; `DelegatingHandler` adds HMAC-SHA256 `X-Signature-256` header
9. **Dead-letter:** after 5 failed attempts, serialize `WebhookJob` + response details to Azure Blob `webhook-dead-letters` container
10. **Usage Redis counters:** `ActionFilter` increments `usage:{keyPrefix}:{endpoint}:{minute}` counters; `/stats` endpoint reads and aggregates
11. **MCP server:** expose `get-api-docs`, `get-webhook-events`, `get-usage-stats` as MCP tools for Cursor IDE integration

## Expected Deliverables

- Working portal with AI chat demonstrating grounded answers
- Demo: ask "What auth schemes does the API support?" — assistant correctly answers from indexed Swagger docs only
- ADR: "RAG vs fine-tuning for API documentation assistant"
- PR description covering API key design (prefix + hash approach)

## Interview Talking Points

- Why store a prefix unhashed alongside the hashed secret? (O(1) lookup without scanning all keys; prefix alone is not sufficient to authenticate)
- How does HMAC-SHA256 signing prevent webhook spoofing? (receiver computes HMAC with shared secret and compares with `FixedTimeEquals`; attacker cannot forge without the secret)
- How do you prevent the AI assistant from making up API endpoints that don't exist? (retrieval grounds the model; system prompt instructs "only answer from provided context"; low temperature)
- How do you keep the RAG index fresh as the API evolves? (CI/CD triggers reindex on OpenAPI spec change; versioned index with blue-green swap)
- What happens if the webhook subscriber endpoint is down for 2 hours? (retry queue with exponential backoff; up to 5 attempts; dead-letter preserves payload for manual retry)
