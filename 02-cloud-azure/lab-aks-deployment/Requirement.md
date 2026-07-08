# Lab: AKS Deployment with Helm

## Objectives

- Containerize a .NET API with a production-ready Dockerfile
- Deploy to Azure Kubernetes Service using Helm charts
- Configure horizontal pod autoscaling and health probes

## Tasks

- [ ] Write multi-stage Dockerfile (build → publish → runtime image)
- [ ] Push image to Azure Container Registry (ACR)
- [ ] Create AKS cluster (use existing or provision with Terraform)
- [ ] Write Helm chart: Deployment, Service, Ingress, ConfigMap, HPA
- [ ] Configure readiness probe and liveness probe
- [ ] Configure HPA (CPU-based autoscaling, min 2 / max 10 pods)
- [ ] Grant AKS kubelet identity pull access to ACR (managed identity)
- [ ] Perform rolling update and rollback demonstration

## Expected Output

Running .NET API on AKS, accessible via Ingress, autoscaling under load. Helm chart reusable for other labs.

## Key Concepts Practiced

`Dockerfile` · `AKS` · `Helm` · `HPA` · `Health probes` · `ACR` · `Rolling update`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
