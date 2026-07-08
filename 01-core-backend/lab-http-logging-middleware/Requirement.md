# lab-http-logging-middleware

## Objectives

- Configure UseHttpLogging to capture request/response details at the HTTP access log level
- Redact sensitive headers and request body fields to prevent PII or credentials from leaking into logs
- Set up W3CLogger for structured W3C-format access logs
- Understand the performance impact of body logging and how to minimise it

## Tasks

- [ ] Enable `UseHttpLogging()` with `HttpLoggingFields.RequestPath | HttpLoggingFields.RequestMethod | HttpLoggingFields.ResponseStatusCode | HttpLoggingFields.Duration`; confirm logs appear in the console
- [ ] Add `RequestHeaders` logging and configure `HttpLoggingOptions.RequestHeaders` allowlist to exclude `Authorization` and `Cookie` headers
- [ ] Enable `RequestBody` logging; set `HttpLoggingOptions.RequestBodyLogLimit = 4096`; demonstrate that body logging buffers the request stream and discuss performance implications
- [ ] Implement `IHttpLoggingInterceptor` (.NET 8) to suppress body logging on `POST /auth/login` (to avoid logging passwords) and enable verbose logging only for `/admin` routes
- [ ] Configure `W3CLogger` with `UseW3CLogging()`; set log directory and rolling interval; inspect the produced W3C-format file
- [ ] Demonstrate the difference from Serilog request logging (`UseSerilogRequestLogging`): Serilog logs at application level with enriched properties; HTTP Logging captures raw HTTP protocol details
- [ ] Add a correlation ID enricher: ensure the `X-Correlation-ID` from incoming request headers propagates to all log entries within that request
- [ ] Write integration tests asserting that the `Authorization` header value is NOT present in captured log output

## Expected Output

An API with HTTP access logging (filtered fields, redacted headers), W3CLogger output, IHttpLoggingInterceptor for per-route control, and integration tests confirming sensitive data is excluded from logs.

## Key Concepts Practiced

`UseHttpLogging` · `HttpLoggingFields` · `sensitive header redaction` · `W3CLogger` · `IHttpLoggingInterceptor` · `request body buffering` · `correlation ID` · `vs Serilog request logging`

## Status

- [ ] Lab completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/lab-http-logging-middleware-pr.md`
