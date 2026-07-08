# Lab: OAuth 2.0 + JWT

## Objectives

- Implement OAuth 2.0 Authorization Code flow with PKCE
- Implement Client Credentials flow for service-to-service auth
- Validate JWT tokens correctly (signature, expiry, audience, issuer)
- Implement refresh token rotation

## Tasks

- [ ] Set up Duende IdentityServer (or use a lightweight custom auth server)
- [ ] Implement Authorization Code + PKCE flow
- [ ] Implement Client Credentials flow
- [ ] Configure a Resource Server (ASP.NET Core API) that validates JWT
- [ ] Implement refresh token endpoint with rotation (old token invalidated on use)
- [ ] Add token introspection endpoint (for opaque tokens)
- [ ] Demonstrate: expired token → 401; wrong audience → 401; valid token → 200
- [ ] Write test: token theft simulation → rotation detects reuse → revoke all tokens

## Expected Output

Auth server + resource server. Both flows demonstrated. Refresh token rotation working.

## Key Concepts Practiced

`OAuth 2.0` · `PKCE` · `JWT validation` · `Refresh token rotation` · `Token introspection`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
