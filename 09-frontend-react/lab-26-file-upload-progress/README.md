# Lab: File Upload with Progress (React)

## Objectives

- Implement single and multi-file upload with per-file progress bars
- Validate file type/size client-side before upload starts
- Support pause/cancel of an in-flight upload
- Handle chunked/resumable upload for large files conceptually or via a real chunking implementation

## Key Concepts

`FormData` · `XHR/axios onUploadProgress` · `drag-and-drop file input` · `client-side file validation` · `cancel token` · `chunked upload`

## Tasks

- [ ] Build a drag-and-drop + click-to-browse file input accepting multiple files
- [ ] Validate file type and max size client-side, rejecting invalid files with a clear message
- [ ] Upload each file with `axios` `onUploadProgress`, rendering a per-file progress bar
- [ ] Add a Cancel button per file that aborts the in-flight request
- [ ] Implement chunked upload for files over a size threshold, reassembled server-side (mock or real)
- [ ] Show a final success/failure summary per file after the batch completes

## Expected Output

A multi-file uploader with accurate per-file progress, working cancel, client-side validation rejection, and a chunked path for large files.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
