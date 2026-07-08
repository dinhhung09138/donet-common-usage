# lab-azure-temp-storage

## Objectives

- Implement a temporary file pattern using Azure Blob Storage with short-lived SAS URLs
- Automate cleanup of expired temp files via lifecycle management policies
- Stream temp uploads without buffering in memory
- Build a background cleanup service for files that escape lifecycle rules

## Key Concepts

`User Delegation SAS` · `SAS expiry` · `Temp container` · `BlobLifecycleManagementPolicy` · `BackgroundService` · `Streaming upload` · `Content-Disposition` · `Blob tags` · `TTL pattern` · `DefaultAzureCredential`

## Tasks

- [ ] Create a dedicated `temp` container with `private` access and no public read
- [ ] Build an upload endpoint that accepts a multipart file, streams it to the `temp` container (no full buffer in memory), and returns a User Delegation SAS URL valid for 15 minutes
- [ ] Add a blob tag `expires-at` with a UTC timestamp on every uploaded temp blob
- [ ] Configure a lifecycle management policy that deletes blobs in the `temp` container after 1 day (safety net)
- [ ] Build a `BackgroundService` that runs every 5 minutes, lists blobs with expired `expires-at` tags, and deletes them
- [ ] Verify that a SAS URL is inaccessible after its expiry window
- [ ] Document the trade-off: lifecycle policy (eventual, server-side) vs background service (near-real-time, client-side)

## Expected Output

An ASP.NET Core Minimal API with `/upload/temp` endpoint returning a short-lived SAS URL, a running `BackgroundService` performing tag-based cleanup, and a lifecycle policy applied to the container.
