# Lab: GitHub Actions CI/CD Pipeline

## Objectives

- Build a full CI/CD pipeline from PR to production deployment
- Use OIDC (workload identity federation) — no stored Azure credentials
- Implement environment-based deployment gates

## Tasks

- [ ] Create CI workflow: trigger on PR → build → run tests → report status
- [ ] Create CD workflow: trigger on merge to main → build image → push to ACR → deploy to AKS
- [ ] Configure OIDC authentication to Azure (no service principal secrets)
- [ ] Add environment protection rules (require manual approval for production)
- [ ] Implement semantic versioning for Docker image tags
- [ ] Add Trivy container vulnerability scan step
- [ ] Add **tfsec** (or Checkov) IaC security scan step — runs before `terraform plan` on PRs; blocks merge if high-severity violations found (e.g., storage account with public blob access, Key Vault without soft delete)
- [ ] Cache NuGet packages to speed up builds
- [ ] Post deployment verification step (hit health endpoint, fail pipeline if not 200)

## Expected Output

Two GitHub Actions workflows. PR check enforced. Merge triggers auto-deploy with OIDC. Scan report in pipeline artifacts.

## Key Concepts Practiced

`GitHub Actions` · `OIDC` · `OIDC to Azure` · `ACR` · `AKS deploy` · `Container scanning` · `tfsec` · `IaC security scanning`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
