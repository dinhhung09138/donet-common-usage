# Lab: Micro-Frontend / Module Federation Basics (Vue)

## Objectives

- Split a single app into a host shell and one independently deployable remote module
- Share a common dependency (framework runtime) between host and remote without duplication
- Handle version-mismatch and remote-unavailable failure modes gracefully
- Understand when micro-frontends are the right call vs unnecessary complexity

## Key Concepts

`Module Federation (Vite plugin)` · `host/remote split` · `shared singleton dependency` · `remote load failure fallback`

## Tasks

- [ ] Configure a `host` app and one `remote` app using Module Federation (`@originjs/vite-plugin-federation`)
- [ ] Expose one remote component and consume it dynamically from the host at runtime
- [ ] Mark the framework runtime as a shared singleton and verify only one copy loads at runtime
- [ ] Simulate the remote being unreachable and render a graceful fallback in the host instead of a crash
- [ ] Deploy (or simulate deploying) host and remote independently and verify the host picks up a new remote version without a host rebuild
- [ ] Write a short README section arguing when this pattern is worth the added complexity vs a monolith SPA

## Expected Output

A host app dynamically loading a remote component at runtime, sharing a single framework instance, with a verified graceful fallback when the remote is unreachable.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
