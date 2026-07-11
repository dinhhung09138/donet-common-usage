# Lab: Response Compression

## Objectives
- Configure Brotli and Gzip compression middleware with correct content-type targeting
- Understand when NOT to compress (BREACH attack, already-compressed types)
- Implement a custom compression provider
- Benchmark compression impact on response size and latency

## Key Concepts
`AddResponseCompression` · `BrotliCompressionProvider` · `GzipCompressionProvider` · `Accept-Encoding` · `content-type filter` · `BREACH attack` · `ICompressionProvider` · `middleware ordering`

## Tasks
- [ ] Install `Microsoft.AspNetCore.ResponseCompression`; register `AddResponseCompression()` with both `BrotliCompressionProvider` and `GzipCompressionProvider`
- [ ] Set `BrotliCompressionProviderOptions.Level = CompressionLevel.Optimal` and `GzipCompressionProviderOptions.Level = CompressionLevel.SmallestSize`; confirm Brotli takes priority when client sends `Accept-Encoding: br, gzip`
- [ ] Restrict compression to specific MIME types: `application/json`, `text/plain`, `text/html`; exclude `image/jpeg`, `image/png`, `application/zip`
- [ ] Demonstrate BREACH attack risk: document (in a code comment or README section) why compressing secrets in HTTPS responses with user-controlled input is dangerous; add a check to disable compression for endpoints returning sensitive data
- [ ] Implement a custom `ICompressionProvider` using Deflate as a third option
- [ ] Measure response size before/after compression for a 50KB JSON payload using `BenchmarkDotNet` or a simple `curl --compressed` comparison
- [ ] Verify that `UseResponseCompression()` is placed before `UseStaticFiles()` and `UseRouting()` in the middleware pipeline
- [ ] Write integration tests asserting that responses include `Content-Encoding: br` when client sends `Accept-Encoding: br`

## Expected Output
An API with Brotli/Gzip compression, correct MIME-type filtering, a custom Deflate provider, BREACH awareness, and passing integration tests.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
