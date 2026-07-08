# Capstone: Distributed Auth Gateway

## Business Context

Build a centralized authentication and authorization service for a microservices ecosystem: SSO with OIDC, multiple MFA options (TOTP + FIDO2/passkeys), Azure Entra ID federation, per-service API scopes, and back-channel logout. This is the most complex auth architecture question at Toptal domain expert interviews.

## Prerequisite Labs

- `lab-identity-server-quickstart`
- `lab-identity-server-ef-persistence`
- `lab-identity-server-ui-login`
- `lab-identity-server-federation`
- `lab-identity-server-api-scopes`
- `lab-mfa-totp`
- `lab-webauthn-fido2`
- `lab-multitenant-authentication`
- `lab-jwt-refresh-token-rotation`
- `lab-oidc-back-channel-logout`

## Functional Requirements

- Login with username/password + MFA (TOTP via authenticator app OR FIDO2 passkey)
- Federation: "Sign in with Microsoft" via Azure Entra ID (OIDC external IdP)
- Per-service API scopes: `orders:read`, `orders:write`, `payments:read`, etc.
- Client Credentials flow for service-to-service auth (background jobs, microservices)
- Refresh token rotation with theft detection (token family invalidation)
- Step-up authentication: high-value operations require MFA re-prompt even with active session
- Back-channel logout: when user logs out, all resource servers notified to invalidate sessions
- Multi-tenant: each tenant has its own user pool and can enable/disable MFA requirement

## Non-Functional Requirements

- Token signing: RS256 with auto-rotating signing keys (JWKS endpoint for public key discovery)
- Session tokens: reference tokens (not JWTs) for SSO sessions — introspection endpoint
- Refresh tokens: hashed at rest (PBKDF2); absolute expiry 30 days; family-based reuse detection
- MFA enrollment: TOTP QR code + recovery codes (bcrypt-hashed, single-use)
- FIDO2 attestation: none verification (any authenticator); user verification required
- Login UI: Razor Pages following IdentityServer quickstart UI pattern

## Architecture

```
Authorization Server (Duende IdentityServer):
  → ConfigurationDbContext (clients, resources, scopes)
  → PersistedGrantDbContext (tokens, grants)
  → Custom ApplicationUser (extends IdentityUser) with:
      TwoFactorEnabled, TotpSecret, FidoCredentials[], RecoveryCodes[]

Login flow:
  1. Username + password → validate via UserManager
  2. If TwoFactorEnabled:
     a. TOTP: display TOTP entry form → VerifyTwoFactorTokenAsync
     b. FIDO2: challenge-response assertion via Fido2NetLib
     c. Recovery code: hash + FixedTimeEquals compare → mark code used
  3. Issue authorization code → client exchanges for token pair

External IdP (Azure Entra ID):
  → AddOpenIdConnect("entra") with Entra OIDC metadata
  → ExternalLoginSignInAsync → map claims → link or create local account
  → Email from Entra trusted only if verified = true claim present

Token issuance:
  → Access token: JWT (RS256, short-lived 15min), scopes from client config
  → Refresh token: opaque reference, hashed in PersistedGrantDbContext
  → ID token: standard OIDC claims + amr (pwd, otp, hwk)

Step-up auth:
  → Resource server checks amr claim
  → If amr doesn't include "otp" or "hwk" for sensitive endpoint:
      → 401 with WWW-Authenticate: Bearer error="insufficient_user_authentication"
  → Client re-initiates authorization with acr_values=mfa

Back-channel logout:
  → User logs out → IdentityServer sends logout_token to all registered clients
  → Resource servers maintain ITicketStore → invalidate session by sub+sid
```

## Implementation Steps

1. **Duende IdentityServer setup:** EF Core persistence (ConfigurationDbContext + PersistedGrantDbContext); seed clients (web app, mobile app, service-to-service)
2. **API scopes:** define per-service scopes; configure audience per ApiResource; scope-based policies in resource servers
3. **Custom ApplicationUser:** extend `IdentityUser` with `TotpSecret`, `FidoCredentials` (JSON column), `RecoveryCodes` (bcrypt-hashed array)
4. **Login Razor Pages:** IdentityServer quickstart UI; integrate TOTP entry page; integrate FIDO2 assertion page
5. **TOTP enrollment:** generate secret via `OtpNet`; generate QR code URI (`otpauth://totp/...`); store encrypted TOTP secret; generate 10 recovery codes (SHA-256 random, bcrypt hash stored)
6. **FIDO2 registration:** `Fido2NetLib` attestation: generate challenge → client calls WebAuthn API → send response → verify → store credential (credentialId + public key + signCount)
7. **FIDO2 assertion:** generate challenge → client signs with platform authenticator → verify assertion + signCount increment
8. **amr claims:** `IProfileService.GetProfileDataAsync` → set `amr` based on how user authenticated (pwd, otp, hwk); IDP adds `mfa` if both pwd+factor used
9. **Azure Entra ID federation:** `AddOpenIdConnect` with tenant authority; `ClaimActions.MapJsonKey` for custom claims; account linking via `ExternalLoginInfo.ProviderKey`
10. **Refresh token rotation:** enable in client config; `PersistedGrantDbContext` stores token family; on reuse detected — revoke entire family
11. **Back-channel logout:** implement `POST /connect/backchannel-logout` endpoint on resource servers; validate `logout_token` (JWT); invalidate session from `ITicketStore`
12. **Multi-tenant:** `TenantId` on ApplicationUser; tenant-specific MFA requirements from `TenantConfig`; per-tenant claim transformations

## Expected Deliverables

- Working auth server with TOTP and FIDO2 enrollment flow (demo-able in browser)
- Sequence diagram: full login flow with FIDO2 + step-up auth
- JWKS endpoint returning current signing keys
- ADR: "Why Duende IdentityServer over building custom JWT issuer"
- PR description covering MFA factor selection and amr claim design

## Interview Talking Points

- How do you represent authentication strength in a JWT without storing state on the resource server? (amr claim — pwd, otp, hwk; resource server validates amr policy without calling back to auth server)
- If a user loses their phone (TOTP app), how do they recover? (recovery codes — pre-generated at enrollment, single-use, bcrypt-hashed; or admin-initiated reset)
- How does FIDO2 make auth phishing-resistant even if the user is on a fake login page? (origin-bound credential — browser includes the real origin in the signed assertion; fake origin fails verification)
- How do you rotate RS256 signing keys without invalidating existing tokens? (JWKS endpoint serves multiple keys by `kid`; resource servers cache JWKS; old tokens use old key until expiry; new tokens use new key)
- How does back-channel logout differ from front-channel logout? (back-channel: server-to-server HTTP call, more reliable; front-channel: iframe/redirect in browser, fails if browser window closed)
