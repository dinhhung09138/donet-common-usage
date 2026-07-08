# lab-azure-container-registry

## Objectives

- Build and push Docker images to Azure Container Registry (ACR)
- Configure ACR webhooks to trigger downstream workflows on image push
- Set up ACR Tasks for automatic builds on git commit
- Understand image tagging strategies and why `latest` is dangerous in production
- Enable Microsoft Defender for Containers to scan images for vulnerabilities

## Key Concepts

`ACR` · `az acr build` · `Docker build/push` · `ACR webhook` · `ACR task` · `Content trust` · `Image tagging (semver, git SHA)` · `Geo-replication` · `Defender for Containers` · `Managed identity` · `acr pull` role · `Azure.Containers.ContainerRegistry` SDK

## Tasks

- [ ] Create an ACR with Basic SKU using Azure CLI or Terraform
- [ ] Write a multi-stage Dockerfile for an ASP.NET Core API (build stage + runtime stage, non-root user)
- [ ] Build and push the image to ACR using `az acr build` (cloud build, no local Docker required)
- [ ] Pull the image using `docker pull` with ACR admin credentials, then switch to managed identity authentication
- [ ] Tag the image with 3 strategies: `latest`, a semver tag (`v1.0.0`), and a git SHA tag — document why `latest` is unreliable in CI/CD
- [ ] Configure an ACR webhook that POSTs to a local endpoint (use `ngrok`) when a new image is pushed
- [ ] Create an ACR task that triggers an image rebuild on every push to a GitHub branch
- [ ] Enable Microsoft Defender for Containers on the registry; push a known-vulnerable image and review the scan report
- [ ] Use `Azure.Containers.ContainerRegistry` SDK in C# to list repositories, list tags, and delete an old image tag programmatically
- [ ] (Optional) Enable geo-replication to a second Azure region and verify image pull latency improvement

## Expected Output

A working ACR with at least one image pushed, a webhook verified, an ACR task configured, and a C# console app that performs SDK-based image management.
