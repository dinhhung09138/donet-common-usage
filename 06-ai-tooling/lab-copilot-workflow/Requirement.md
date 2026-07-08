# lab-copilot-workflow

GitHub Copilot prompting strategies and AI-assisted development workflow — a practice-based lab with documented techniques.

## Objectives

- Master `@workspace` context for project-aware suggestions
- Apply specificity, examples, and constraint techniques for better completions
- Use Copilot CLI (`gh copilot suggest` / `gh copilot explain`)
- Generate PR descriptions and ADRs with AI assistance
- Use Copilot for code review: spotting bugs and suggesting improvements
- Configure `.github/copilot-instructions.md` for project-wide guidance

## Key Concepts

`@workspace`, `#file`, `#selection` context references, prompt specificity (what/how/why), few-shot examples in comments, constraint prompting ("without using LINQ", "in under 10 lines"), Copilot CLI `gh copilot suggest`, Copilot Chat slash commands (`/explain`, `/fix`, `/tests`, `/doc`), `.github/copilot-instructions.md`, Copilot for PRs

## Tasks

1. Install GitHub Copilot extension in VS Code and authenticate
2. Practice 5 prompting techniques on a real lab (e.g. `lab-minimal-api`):
   - Vague → specific prompt comparison
   - Example-driven completion
   - Constraint-based generation
   - `@workspace` cross-file query
   - `/tests` slash command for unit test generation
3. Install `gh` CLI and practice `gh copilot suggest "how do I list running Docker containers"`
4. Generate a PR description for a completed lab using `/explain` + manual refinement
5. Create `.github/copilot-instructions.md` documenting project conventions
6. Document your best prompts in `prompts.md` for future reuse

## Expected Output

- `prompts.md` file: 10+ reusable prompts with before/after quality comparison
- `.github/copilot-instructions.md` configured for this project
- PR description generated with Copilot assistance (saved as `PR-DESCRIPTION.md` in this lab folder)
