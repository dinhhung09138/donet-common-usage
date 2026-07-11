# Lab: State Persistence & Offline Cache (Vue)

## Objectives

- Persist selected app state across reloads (localStorage/IndexedDB) with versioned migrations
- Cache API responses client-side to serve stale-while-revalidate data
- Detect online/offline transitions and queue mutations made while offline
- Replay queued offline mutations on reconnect with conflict awareness

## Key Concepts

`persisted store (pinia-plugin-persistedstate or manual)` · `IndexedDB (idb)` · `stale-while-revalidate` · `navigator.onLine + online/offline events` · `offline mutation queue`

## Tasks

- [ ] Persist a slice of the Pinia store with a version key and a migration function for schema changes
- [ ] Cache a list-fetch response in IndexedDB and render cached data instantly while revalidating in the background
- [ ] Detect offline via `navigator.onLine` and the `online`/`offline` window events, showing a status banner
- [ ] Queue a mutation (e.g. create item) made while offline instead of failing it outright
- [ ] Replay the queued mutation automatically on reconnect and surface success/conflict to the user
- [ ] Write a migration test proving an old persisted-state shape upgrades cleanly to the new one

## Expected Output

An app that survives a reload with persisted state, serves cached data instantly offline, and successfully replays a queued create-mutation once connectivity returns.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
