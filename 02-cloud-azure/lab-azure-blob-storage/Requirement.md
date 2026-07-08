# lab-azure-blob-storage

## Objectives

- Perform full CRUD operations on Azure Blob Storage using the v12 SDK
- Generate the 3 types of SAS tokens and understand their security trade-offs
- Configure blob access tiers and automate transitions with lifecycle policies
- Stream large files without buffering the entire payload in memory
- Enable soft delete and versioning for data protection

## Key Concepts

`BlobServiceClient` · `BlobContainerClient` · `BlobClient` · `Service SAS` · `Account SAS` · `User Delegation SAS` · `Hot / Cool / Archive` · `BlobLifecycleManagementPolicy` · `UploadAsync(stream)` · `DownloadStreamingAsync` · `Soft delete` · `Versioning` · `Append blob` · `DefaultAzureCredential`

## Tasks

- [ ] Create a container and upload a file using `BlobContainerClient.UploadBlobAsync`
- [ ] Download a blob as a stream and write it to a local file without loading it fully into memory
- [ ] List blobs with prefix filtering and metadata
- [ ] Generate a Service SAS URL (read-only, 1-hour expiry) and verify it works without credentials
- [ ] Generate a User Delegation SAS using `DefaultAzureCredential` and a managed identity — explain why this is preferred over Account SAS
- [ ] Set a blob's access tier to `Cool`; then `Archive`; then rehydrate back to `Hot` (observe rehydration delay)
- [ ] Configure a lifecycle management policy: move blobs to Cool after 30 days, delete after 90 days
- [ ] Enable soft delete (7-day retention) on a container; delete a blob; restore it
- [ ] Enable versioning; update a blob; list all versions; restore a previous version
- [ ] Build an append blob that accumulates log lines without overwriting existing content

## Expected Output

An ASP.NET Core Minimal API with endpoints for upload, download (streaming), and SAS URL generation. Policy and versioning configurations applied via SDK, verified in Azure Portal or Azure Storage Explorer.
