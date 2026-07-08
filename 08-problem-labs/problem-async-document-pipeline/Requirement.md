# Problem Lab: Async Document Processing Pipeline

> **Category:** Feature Building
> **Effort:** 2–3 days
> **Technologies:** Streaming upload, Azure Blob Storage, Azure Queue Storage, BackgroundService, Azure AI Document Intelligence, SignalR, Hangfire, IOutputCacheStore

---

## Scenario

A legal-tech platform needs users to upload contracts (PDF, DOCX). The system must virus-scan the file, extract key clauses using Azure AI Document Intelligence, and store the results. Currently the upload endpoint does all of this synchronously — it takes 45 seconds per file and times out for large PDFs. Users see a browser timeout with no feedback.

**Business impact:** 20% of document uploads time out, requiring manual resubmission. The support team spends 2 hours daily handling "my upload failed" tickets.

---

## The Problem / Requirement

**Functional requirements:**
- Client uploads file → API returns `jobId` immediately (< 200ms response)
- Background processing: virus scan → AI extraction → store to Azure Blob → update job status
- Client polls `GET /documents/jobs/{jobId}` for status OR subscribes via SignalR for real-time progress
- Final result: structured JSON (extracted clauses) accessible via `GET /documents/{documentId}`

**Non-functional requirements:**
- Files up to 100MB must not be buffered in memory (streaming upload)
- If AI extraction fails: retry 2× then mark job as `Failed` with error detail
- Job status must survive pod restart (not in-memory)
- Processing throughput: 50 concurrent documents without OOM

**Edge cases:**
- Virus detected → delete file from blob, mark job `Rejected`, notify client
- AI extraction returns partial results (timeout) → store partial, mark `PartiallyProcessed`
- Client disconnects from SignalR mid-process → status still available via polling

---

## Solution Design

**Option A — Synchronous pipeline in upload handler:**
Current approach. Blocks HTTP thread for 45s, scales poorly, no progress feedback.

**Option B — Async pipeline with Azure Queue Storage + BackgroundService + SignalR (recommended):**
Upload endpoint streams file directly to Azure Blob Storage (no memory buffer), enqueues a processing message, returns `jobId`. Background `DocumentProcessingWorker` dequeues, runs pipeline stages, updates status in DB, pushes progress to SignalR group. Client polls or listens on SignalR.

**Why Option B:**
- Upload endpoint stays fast (< 200ms) regardless of file size or processing time
- Processing scales independently — add more worker instances, zero change to API
- SignalR progress is optional for clients that support it; polling endpoint is the universal fallback

```
Client
  │ POST /documents/upload (multipart stream)
  ▼
API: Stream file → Azure Blob Storage
     Store Job record (status: Pending)
     Enqueue message to Azure Queue Storage
     Return 202 Accepted { jobId }

Azure Queue Storage
  │
  ▼
DocumentProcessingWorker (BackgroundService)
  ├── ClamAV virus scan (stage 1)
  │     │ INFECTED → delete blob, update job: Rejected, push SignalR
  ├── Azure AI Document Intelligence (stage 2)
  │     │ PARTIAL → store partial result, update job: PartiallyProcessed
  └── Store extracted JSON to Azure Blob (stage 3)
        update job: Completed
        push SignalR progress to jobId group
```

---

## Implementation Tasks

1. **Streaming multipart upload to Azure Blob Storage**
   - Use `Request.BodyReader` (PipeReader) or IFormFile with streaming — never `ReadToEndAsync()`
   - Generate `blobName = {tenantId}/{jobId}/{filename}`; set content-type header
   - Acceptance: Upload 100MB file without memory spike (dotnet-counters: heap stays flat)

2. **Job entity + EF Core + Azure Queue Storage enqueue**
   - `DocumentJob`: Id, TenantId, BlobPath, Status, ErrorMessage, CreatedAt, CompletedAt
   - Enqueue `DocumentProcessingMessage { JobId, BlobPath, TenantId }` to Azure Queue
   - Return `202 Accepted { jobId, statusUrl, signalRGroup }`
   - Acceptance: Job record in DB with `Pending` status; message visible in Azure Queue Storage

3. **Implement `DocumentProcessingWorker : BackgroundService`**
   - Dequeue message, acquire lease (visibility timeout = processing time estimate)
   - Stage pipeline: `VirusScanStage → AiExtractionStage → StorageStage`
   - Update job status at each stage transition
   - Extend visibility timeout for large files during AI processing
   - Acceptance: Worker processes message end-to-end; job reaches `Completed`

4. **ClamAV virus scan stage**
   - Use `nClam` to scan blob bytes (stream from blob, do not download to disk)
   - On infected: delete blob, update job `Rejected`, push SignalR event, delete queue message
   - Acceptance: Test with EICAR test string; verify blob deleted and job marked Rejected

5. **Azure AI Document Intelligence extraction stage**
   - Call `DocumentAnalysisClient.AnalyzeDocumentAsync()` with `prebuilt-contract` model
   - Handle `OperationCanceledException` (timeout) → mark `PartiallyProcessed` with available results
   - Retry 2× on 503/429 with exponential backoff
   - Acceptance: Real PDF processed; extracted fields stored as JSON in Azure Blob

6. **SignalR progress push from BackgroundService**
   - `IHubContext<DocumentHub>` injected into worker
   - Push event per stage: `{ jobId, stage, status, progressPercent }`
   - Client joins group `document:{jobId}` after upload to receive events
   - Acceptance: Frontend receives 3 progress events (Scanning → Extracting → Completed)

7. **Polling endpoint with Output Caching**
   - `GET /documents/jobs/{jobId}` → returns current job status from DB
   - Output cache 5s with `VaryByRouteValue("jobId")`; evict tag `job:{jobId}` on status change
   - Acceptance: Polling endpoint returns correct status without hitting DB on every poll

---

## Acceptance Criteria

- [ ] Upload 100MB PDF: API responds in < 200ms; no memory spike
- [ ] Job status transitions visible via SignalR in real-time
- [ ] EICAR test file → job marked `Rejected`, blob deleted
- [ ] AI extraction timeout → job marked `PartiallyProcessed` (not `Failed`)
- [ ] Pod restart during processing → job resumes from queue (not lost)
- [ ] Polling endpoint cached; DB not hit on every poll
- [ ] 50 concurrent uploads: no OOM (verified with dotnet-counters)

---

## Interview Talking Points

**Situation:** Legal-tech platform's document upload was synchronous — 45-second processing caused browser timeouts. 20% of uploads failed, generating 2 hours of daily support work.

**Task:** Re-architect the pipeline so uploads return immediately and processing happens asynchronously with real-time progress feedback.

**Action:**
- Decoupled upload from processing by streaming the file directly to Azure Blob Storage and enqueuing a processing message — the HTTP endpoint now returns in under 200ms regardless of file size
- Built a `DocumentProcessingWorker` BackgroundService that pulls from Azure Queue Storage and runs virus scan → AI extraction → storage as staged pipeline, pushing progress to SignalR after each stage
- Used visibility timeout extension to prevent Azure Queue from re-delivering messages during long AI extraction, avoiding duplicate processing

**Result:** Upload timeout rate dropped from 20% to 0%. Support tickets for upload failures eliminated. The same worker scales horizontally — adding 2 more instances doubled throughput during high-volume periods.

**Follow-up questions to prepare:**
- "What if the AI service is down for 2 hours?" → Messages stay in Azure Queue with visibility timeout; worker retries 2× then re-enqueues with delay; job stays `Pending` and client is notified via SignalR that processing is delayed
- "How do you handle files that take longer than the visibility timeout?" → Extend visibility timeout in a background timer while processing; release the message if the worker crashes so another instance picks it up

---

## Key Concepts

`Streaming upload` · `Azure Blob Storage` · `Azure Queue Storage` · `BackgroundService` · `Azure AI Document Intelligence` · `SignalR IHubContext` · `nClam` · `Visibility timeout` · `IOutputCacheStore` · `PipeReader`

---

## Status

- [ ] Completed
- [ ] PR description written (STAR format) → `PR-DESCRIPTION.md` in this lab folder
- [ ] ADR written → `ADR.md` in this lab folder
- [ ] Added to real-world-cases → `technical-interview/real-world-cases/`
