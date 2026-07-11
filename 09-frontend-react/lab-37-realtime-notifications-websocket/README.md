# Lab: Real-Time Notifications via WebSocket (React)

## Objectives

- Establish a WebSocket (or SignalR) connection with automatic reconnect and backoff
- Push real-time notifications into the global toast/notification-center UI
- Keep a notification center (bell icon + unread count + list) in sync with server events
- Handle connection-lost UX (stale-data banner) gracefully

## Key Concepts

`WebSocket/SignalR client` · `reconnect with backoff` · `event-to-store dispatch` · `unread count badge` · `connection-state UI`

## Tasks

- [ ] Connect to a WebSocket (or SignalR hub) on app mount, closing cleanly on unmount
- [ ] Implement reconnect-with-exponential-backoff on unexpected disconnect
- [ ] Dispatch incoming events into the global store, triggering a toast and updating a notification list
- [ ] Build a bell icon with unread count badge and a dropdown listing recent notifications
- [ ] Mark-as-read on open, syncing read state back to the server
- [ ] Show a persistent banner when the connection is lost, cleared automatically on reconnect

## Expected Output

A live notification bell that reflects server-pushed events in real time, survives a simulated disconnect with auto-reconnect, and shows a clear connection-lost state.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
