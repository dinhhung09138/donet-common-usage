# Lab: Authentication & JWT Session Handling (React)

## Objectives

- Implement login/logout flows storing and refreshing a JWT session
- Attach the access token to outgoing requests and handle silent refresh on expiry
- Protect routes so unauthenticated users are redirected to login and back
- Handle multi-tab logout/session sync consistently

## Key Concepts

`JWT access/refresh token` · `axios interceptor token attach + refresh` · `ProtectedRoute` · `storage strategy (httpOnly cookie vs memory)` · `storage/tab sync event`

## Tasks

- [ ] Build a login form calling a mock auth API and storing the access token appropriately (prefer in-memory/httpOnly cookie over localStorage; document the trade-off)
- [ ] Attach the access token to every API request via an axios request interceptor
- [ ] Implement silent token refresh on a 401 response, retrying the original request once
- [ ] Build a `ProtectedRoute` wrapper redirecting unauthenticated users to `/login?redirect=`
- [ ] Redirect back to the originally requested page after successful login
- [ ] Sync logout across browser tabs using the `storage` event

## Expected Output

A login-protected app where an expired token triggers a transparent silent refresh, unauthenticated access redirects and returns correctly, and logout propagates to all open tabs.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
