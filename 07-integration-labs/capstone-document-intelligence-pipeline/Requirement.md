# Capstone: Document Intelligence Pipeline

## Business Context

Build a scalable document processing system: users upload contracts/invoices → pipeline virus-scans, OCR-extracts structured data with Azure AI, stores results, and generates a PDF report. This pattern appears in legal-tech, fintech, and insurance SaaS products.

## Prerequisite Labs

- `lab-file-upload-processing`
- `lab-azure-blob-storage`
- `lab-azure-queue-storage`
- `lab-background-services`
- `lab-signalr-hubs`
- `lab-pdf-generation`
- `lab-polly-resilience`
- `lab-azure-openai-dotnet` (or `lab-semantic-kernel-basics`)

## Functional Requirements

- User uploads document (PDF, DOCX, PNG) up to 50MB via streaming multipart
- Pipeline stages: virus scan (ClamAV) → type validation → Azure AI Document Intelligence extraction → store structured JSON → generate PDF summary report
- Real-time progress reported to user (SignalR): Uploading → Scanning → Extracting → Report Ready
- Failed documents quarantined with reason; user notified
- Download PDF report via short-lived SAS URL (5 minutes)

## Non-Functional Requirements

- Upload endpoint must not buffer entire file in memory (streaming required)
- Antivirus scan is synchronous and slow (up to 30s) — must run off the request thread
- Azure AI calls: Polly retry (3 attempts, exponential backoff) + circuit breaker
- Concurrent processing: up to 20 documents simultaneously (Channel<T> with bounded capacity)
- Blob storage with lifecycle policy: source documents deleted after 30 days; reports kept 1 year

## Architecture

```
POST /documents/upload (streaming multipart)
  → validate file type (magic bytes, not extension)
  → stream to Azure Blob (temp container)
  → enqueue DocumentUploaded message to Azure Queue
  → return 202 Accepted + documentId

Background worker (BackgroundService):
  → dequeue message
  → download blob stream
  → ClamAV virus scan
    ✗ infected → quarantine blob + notify user (SignalR + email)
    ✓ clean → proceed
  → call Azure AI Document Intelligence (with Polly retry)
  → store extraction JSON in Blob + SQL record
  → generate PDF report (QuestPDF)
  → upload PDF to reports container
  → generate SAS URL (5 min expiry)
  → notify user via SignalR (status: ReportReady + SAS URL)
```

## Implementation Steps

1. **Streaming upload endpoint:** use `Request.Body` stream directly; avoid `IFormFile` buffering for large files
2. **Magic byte validation:** read first 8 bytes to detect real file type (PDF = `%PDF`, PNG = `\x89PNG`)
3. **Azure Blob:** upload to `temp-documents` container; configure lifecycle policy (delete after 30 days)
4. **Azure Queue:** enqueue `DocumentUploadedMessage` with blobName, documentId, userId
5. **BackgroundService:** `Channel<DocumentUploadedMessage>` bounded to 20; dequeue from Azure Queue, push to channel
6. **ClamAV scan:** `nClam` NuGet; stream blob content to ClamAV socket; handle `VirusFound` result
7. **Quarantine:** move blob to `quarantine` container; update DB status; send SignalR `DocumentQuarantined` event
8. **Azure AI extraction:** `DocumentAnalysisClient` from Azure.AI.FormRecognizer; Polly pipeline (retry + circuit breaker + timeout)
9. **PDF generation:** QuestPDF document with extraction fields, page header, table layout
10. **SAS URL:** user-delegation SAS with 5-minute expiry; return in SignalR event
11. **SignalR progress:** `DocumentProgressHub`; worker calls `IHubContext` at each stage with `{ stage, progress% }`
12. **Integration tests:** mock ClamAV (return clean), mock Azure AI, assert SignalR events received via test client

## Expected Deliverables

- End-to-end working pipeline (can test with a real PDF)
- Sequence diagram showing async stages with fallback paths
- ADR: "Why Azure Queue Storage over Service Bus for this pipeline" (ordering not needed, cost, simplicity)
- PR description covering streaming upload + async processing design

## Interview Talking Points

- Why not process the document synchronously in the upload request? (30s antivirus blocks request thread; client gets 202 instead of timeout)
- How do you handle a crash between queue dequeue and processing completion? (visibility timeout + DequeueCount threshold for poison messages)
- How would you scale this to 10,000 documents/day? (multiple BackgroundService instances, partition queue by document type)
- Why stream to Blob before enqueuing instead of passing file content in the queue message? (Azure Queue message limit: 64KB; Blob handles any size)
- How do you prevent a re-uploaded file from being processed twice? (idempotency key = SHA-256 hash of file content stored in DB; skip if already processed)
