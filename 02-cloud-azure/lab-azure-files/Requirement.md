# lab-azure-files

## Objectives

- Perform file and directory operations on Azure File Shares using the C# SDK
- Understand when to choose Azure Files over Blob Storage
- Mount a file share via SMB on Windows and verify access
- Generate SAS tokens scoped to a file share or individual file
- Understand Azure File Sync and NFS 4.1 for Linux lift-and-shift scenarios

## Key Concepts

`ShareServiceClient` · `ShareClient` · `ShareDirectoryClient` · `ShareFileClient` · `SMB 3.0` · `NFS 4.1` · `File Share SAS` · `Azure File Sync` · `UploadAsync` · `DownloadAsync` · `Quota` · `Snapshot` · `Blob Storage vs Azure Files`

## Tasks

- [ ] Create a file share with a 5 GB quota using `ShareServiceClient`
- [ ] Create a nested directory structure (`logs/2026/06/`) using `ShareDirectoryClient`
- [ ] Upload a text file to the share using `ShareFileClient.UploadAsync`
- [ ] Download the file and verify its content
- [ ] List all files and directories recursively under the share root
- [ ] Generate a SAS token for a specific file (read-only, 30-minute expiry) and access it via HTTP
- [ ] Take a share snapshot and restore a file from it
- [ ] Mount the file share via SMB on Windows (`net use Z: \\<account>.file.core.windows.net\<share> /u:...`) and verify read/write
- [ ] Write a comparison document: Azure Files vs Blob Storage — protocol, use case, latency, cost
- [ ] Research and document: when would you use Azure File Sync and when NFS 4.1?

## Expected Output

A console application demonstrating all SDK operations, a mounted drive verified with a file read/write, and a written comparison document in `docs/files-vs-blob.md`.
