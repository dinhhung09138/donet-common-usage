# Lab: ASP.NET Core SignalR Hubs

## Objectives
- Design and implement a real-time SignalR hub exposing server-to-client push and client-to-server invocation for a realistic feature (e.g. live notifications, chat, dashboard updates).
- Use SignalR groups to scope broadcasts to a subset of connections (per tenant, per resource, per user role) instead of broadcasting globally.
- Implement authenticated hub connections and authorize hub methods/groups based on the connected user's identity/claims.
- Handle client reconnection and connection-lifecycle events so the UI/state stays consistent across transient network drops.

## Key Concepts
`Hub` · `IHubContext<T>` · `Clients.Group` / `Clients.Caller` / `Clients.Others` · `Groups.AddToGroupAsync` · `[Authorize]` on hubs · `Automatic reconnect (withAutomaticReconnect)` · `OnConnectedAsync` / `OnDisconnectedAsync` · `Connection ID` · `Transport negotiation (WebSockets/SSE/Long Polling)`

## Tasks
- [ ] Create a SignalR hub exposing a method the client can invoke and a server-initiated push method invoked from an API controller via `IHubContext<THub>`.
- [ ] Implement `OnConnectedAsync`/`OnDisconnectedAsync` to add/remove connections from a group keyed by a business identifier (e.g. `order-{orderId}` or `tenant-{tenantId}`).
- [ ] Send targeted messages using `Clients.Group(...)`, `Clients.Caller`, and `Clients.Others` and verify each reaches only the intended recipients.
- [ ] Secure the hub with `[Authorize]`, pass the access token from a JS/`.NET` client, and reject unauthenticated connection attempts.
- [ ] Configure the client with `withAutomaticReconnect()` and implement `onreconnecting`/`onreconnected` handlers that resynchronize state lost during the disconnect window.
- [ ] Simulate a network drop (kill/restart the server or block the connection) and verify the client reconnects and correctly rejoins its group.
- [ ] Load-test with multiple concurrent client connections and confirm group-scoped delivery remains correct under concurrency.

## Expected Output
A running ASP.NET Core app with a secured SignalR hub where two or more clients in different groups each receive only the messages targeted at their group, an authenticated connection is rejected without a valid token, and a forced server restart demonstrates automatic client reconnection with group membership correctly re-established.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
