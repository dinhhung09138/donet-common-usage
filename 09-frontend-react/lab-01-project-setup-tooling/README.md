# Lab: Project Setup & Tooling (React)

## Objectives

- Scaffold a production-grade React project with a clean, scalable folder structure
- Configure linting, formatting, and strict type-checking as CI-enforceable quality gates
- Set up path aliases and environment-based build configuration
- Establish a component/feature folder convention that scales past a single-developer prototype

## Key Concepts

`Vite` · `TypeScript strict mode` · `ESLint` · `Prettier` · `tsconfig path aliases` · `feature-folder structure`

## Tasks

- [ ] Scaffold the project with `npm create vite@latest -- --template react-ts`
- [ ] Configure ESLint + Prettier with a shared config and a pre-commit hook
- [ ] Set up `tsconfig.json` path aliases (`@/components`, `@/features`)
- [ ] Organize a `src/features/<feature>` folder convention (components, hooks, api, types)
- [ ] Add `.env.development` / `.env.production` and read values via `import.meta.env`
- [ ] Verify `npm run build` produces a working production bundle

## Expected Output

A runnable React app with zero lint/type errors, alias imports resolving correctly, and a production build that boots without console errors.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
