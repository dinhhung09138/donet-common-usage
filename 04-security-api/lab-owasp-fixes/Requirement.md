# Lab: OWASP Top 10 — Vulnerable App → Fixed

## Objectives

- Identify the most common security vulnerabilities in a .NET API
- Fix each vulnerability with the correct mitigation
- Understand why each fix works

## Vulnerabilities Covered

| # | Vulnerability | OWASP 2021 |
|---|---------------|------------|
| 1 | SQL Injection | A03 Injection |
| 2 | Broken Object-Level Authorization (IDOR) | A01 Broken Access Control |
| 3 | Stored XSS via API response | A03 Injection |
| 4 | Hardcoded secrets in config | A02 Cryptographic Failures |
| 5 | Missing rate limiting on login | A07 Identification and Authentication Failures |
| 6 | Verbose error messages exposing stack trace | A05 Security Misconfiguration |
| 7 | Mass assignment (over-posting) | A08 Software and Data Integrity Failures |

## Tasks

- [ ] Create `VulnerableOrdersController` with all 7 vulnerabilities
- [ ] Write an attack script for each (curl commands or unit tests that exploit the vulnerability)
- [ ] Fix SQL Injection: parameterized queries / EF Core
- [ ] Fix IDOR: ownership check before returning resource
- [ ] Fix XSS: output encoding, Content-Security-Policy header
- [ ] Fix hardcoded secrets: move to Key Vault (reference `lab-key-vault-secrets`)
- [ ] Fix missing rate limiting: reference `lab-rate-limiting`
- [ ] Fix verbose errors: use ProblemDetails without stack traces in production
- [ ] Fix mass assignment: use explicit input DTOs, never bind directly to entities

## Expected Output

`VulnerableController` (documented, exploitable) + `SecureController` (fixed). Side-by-side diff in README.

## Key Concepts Practiced

`OWASP Top 10` · `SQL injection` · `IDOR` · `XSS` · `Mass assignment` · `ProblemDetails`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
