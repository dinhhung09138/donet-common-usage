# Lab: Environment Config & Multi-Env Builds (Vue)

## Objectives

- Manage API base URLs and feature toggles across dev/staging/prod builds
- Prevent secrets from leaking into client bundles
- Build a runtime config strategy for values that can't be baked in at build time
- Verify environment-specific builds with a build-time smoke check

## Key Concepts

`import.meta.env` · `VITE_ prefix` · `build-time vs runtime config` · `public runtime config.json` · `bundle inspection`

## Tasks

- [ ] Define `VITE_API_BASE_URL` and other config values per `.env.<mode>` file
- [ ] Explain and demonstrate why only `VITE_`-prefixed vars are exposed to the client bundle
- [ ] Add a `public/runtime-config.json` fetched at app boot for values that must change without a rebuild
- [ ] Build a typed `config` module that merges build-time and runtime values with sane defaults
- [ ] Run `npm run build -- --mode staging` and verify the bundle contains the staging API URL
- [ ] Inspect the built bundle to confirm no secret/service-role key ended up in client JS

## Expected Output

Three distinct builds (dev/staging/prod) with verifiably different config baked in, plus one runtime-overridable value proven to change without rebuilding.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
