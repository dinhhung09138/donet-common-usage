# Capstone: Compliance Audit System

## Business Context

Build a tamper-proof, queryable audit logging system for fintech or healthcare applications. Every state change on sensitive entities (accounts, transactions, patient records) must be logged, encrypted, immutable, and exportable for regulatory review. A critical system design question for any regulated-industry backend role.

## Prerequisite Labs

- `lab-ef-core-interceptors`
- `lab-outbox-pattern`
- `lab-encryption-dotnet`
- `lab-azure-blob-storage`
- `lab-cqrs-pattern`
- `lab-opentelemetry-tracing`
- `lab-serilog-structured-logging`
- `lab-advanced-sql`

## Functional Requirements

- Every write to sensitive entities auto-generates an AuditEntry (who, what, when, before, after)
- AuditEntry content is AES-GCM encrypted — plaintext never stored in DB
- Audit entries are immutable: no UPDATE or DELETE ever runs against the audit table
- Compliance export: generate CSV/PDF of all audit entries for a date range and entity type
- Queryable read model: filter by userId, entityType, action, dateRange (< 200ms P99)
- Blob archive: nightly job moves entries older than 90 days to Azure Blob (immutable tier) and prunes from DB

## Non-Functional Requirements

- AuditEntry write must be atomic with the business operation (outbox pattern — same transaction)
- Encryption key lives in Azure Key Vault — never in app config or environment variables
- Immutability enforced at two levels: SQL (INSERT-only user, no UPDATE/DELETE grants) and app (EF Core SaveChanges interceptor rejects mutations to AuditEntry)
- OpenTelemetry trace ID included in every AuditEntry for cross-system correlation
- PII fields in audit payload encrypted with per-record DEK (envelope encryption)

## Architecture

```
Business operation (e.g., UpdateAccount):
  → EF Core ISaveChangesInterceptor detects changed entities
  → for each changed entity: serialize Before/After state as JSON
  → encrypt payload with DEK (AES-GCM)
  → wrap DEK with KEK from Azure Key Vault
  → insert AuditEntry (ciphertext + wrapped DEK) + OutboxMessage in same transaction

Outbox BackgroundService:
  → dequeue OutboxMessage
  → publish AuditEntryCreated event to MassTransit

AuditEntryCreated consumer:
  → update CQRS read model (AuditEntrySummary — unencrypted metadata only)
  → index: userId, entityType, action, timestamp

Compliance export request:
  → query read model for matching entries
  → decrypt each entry (unwrap DEK from Key Vault → decrypt payload)
  → generate CSV or QuestPDF report

Nightly archival Hangfire job:
  → query entries older than 90 days
  → upload to Azure Blob (immutable storage tier — WORM policy)
  → delete from SQL after confirming blob write
```

## Implementation Steps

1. **AuditEntry entity:** `Id`, `EntityType`, `EntityId`, `Action` (Created/Updated/Deleted), `UserId`, `TraceId`, `Timestamp`, `EncryptedPayload` (byte[]), `WrappedDek` (byte[]), `Nonce` (byte[])
2. **EF Core interceptor:** `ISaveChangesInterceptor.SavingChangesAsync` — detect `EntityState.Modified/Deleted` on auditable entities; serialize `OriginalValues` + `CurrentValues`
3. **Envelope encryption:** generate random 256-bit DEK per AuditEntry; encrypt payload with AES-GCM; wrap DEK with KEK from Azure Key Vault (`KeyClient.WrapKeyAsync`)
4. **Outbox pattern:** insert `AuditEntry` + `OutboxMessage` in same `DbTransaction`; background service publishes and marks message delivered
5. **CQRS read model:** `AuditEntrySummary` — unencrypted metadata (userId, entityType, action, timestamp, traceId); updated by MassTransit consumer
6. **SQL immutability:** create a restricted EF user with INSERT-only on AuditEntry; interceptor checks entity state and throws if mutation attempted via app code
7. **Compliance export:** decrypt each matching entry (Key Vault unwrap → AES-GCM decrypt); write to `CsvWriter` stream or QuestPDF; stream response (no buffering all rows in memory)
8. **Azure Blob archival:** Hangfire nightly job; upload serialized AuditEntry JSON to immutable Blob container (WORM); verify blob properties before deleting from SQL
9. **OpenTelemetry:** inject current `Activity.TraceId` into AuditEntry at interceptor time; enrich Serilog with `{TraceId}` for log correlation
10. **Integration tests:** verify AuditEntry is created for every write; verify decryption succeeds; verify cross-tenant isolation

## Expected Deliverables

- Working audit system demonstrating immutability + encryption
- Sequence diagram: business write → audit capture → encryption → outbox → archive
- ADR: "Envelope encryption with Azure Key Vault vs storing encryption key in app config"
- PR description covering the interceptor-based audit capture approach

## Interview Talking Points

- How do you ensure an audit entry is never missed, even if the application crashes after the business write but before the audit write? (same transaction via interceptor; outbox ensures event delivery)
- How do you query audit entries without decrypting every row? (unencrypted metadata in read model; only decrypt payload when showing details or exporting)
- What is envelope encryption and why use it instead of encrypting everything with one master key? (per-record DEK means key rotation only re-wraps DEKs, not re-encrypts all data; breach of one DEK only exposes one record)
- How do you prove immutability in court? (Azure Blob WORM policy — time-based retention lock; SQL INSERT-only user; hash chain on AuditEntry sequence)
- How would you handle GDPR right-to-erasure for encrypted audit logs? (destroy the DEK for that user's entries — ciphertext becomes unreadable without re-encrypting)
