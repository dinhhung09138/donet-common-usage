# Lab: Project Setup & Tooling (Vue)

## Objectives

- Scaffold a production-grade Vue project with a clean, scalable folder structure
- Configure linting, formatting, and strict type-checking as CI-enforceable quality gates
- Set up path aliases and environment-based build configuration
- Establish a component/feature folder convention that scales past a single-developer prototype

## Key Concepts

`Vite` · `TypeScript strict mode` · `ESLint (vue-eslint-parser)` · `Prettier` · `vite alias resolve` · `feature-folder structure`

## Tasks

- [ ] Scaffold the project with `npm create vite@latest -- --template vue-ts`
- [ ] Configure ESLint (`eslint-plugin-vue`) + Prettier with a shared config and a pre-commit hook
- [ ] Set up `vite.config.ts` and `tsconfig.json` path aliases (`@/components`, `@/features`)
- [ ] Organize a `src/features/<feature>` folder convention (components, composables, api, types)
- [ ] Add `.env.development` / `.env.production` and read values via `import.meta.env`
- [ ] Verify `npm run build` produces a working production bundle

## Expected Output

A runnable Vue app with zero lint/type errors, alias imports resolving correctly, and a production build that boots without console errors.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
