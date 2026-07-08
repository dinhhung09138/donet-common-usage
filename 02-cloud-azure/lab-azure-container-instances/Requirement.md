# lab-azure-container-instances

## Objectives

- Provision and manage Azure Container Instances (ACI) on-demand from C# using the Azure SDK
- Understand container groups, restart policies, and when ACI is preferable over AKS
- Inject environment variables and secrets securely without hardcoding values
- Mount Azure Files volumes into a running ACI container
- Build a real use case: on-demand ephemeral job runner triggered via API

## Key Concepts

`Azure.ResourceManager.ContainerInstance` · `ContainerGroupData` · `ContainerData` · `RestartPolicy (Always / Never / OnFailure)` · `EnvironmentVariable` · `SecretEnvironmentVariable` · `Volume mount` · `Azure Files volume` · `ContainerGroup status polling` · `ACI vs AKS` · `Managed identity` · `DefaultAzureCredential`

## Tasks

- [ ] Create an ACI container group via C# SDK: pull `mcr.microsoft.com/dotnet/runtime:8.0`, pass a command override, set `RestartPolicy = Never`
- [ ] Pass environment variables to the container (non-secret values via `EnvironmentVariable`, secrets via `SecretEnvironmentVariable` — note the difference)
- [ ] Poll the container group status until it reaches `Terminated` or `Running`; retrieve the exit code
- [ ] Retrieve container logs from a stopped container using `GetContainerLogsAsync`
- [ ] Mount an Azure Files share as a volume inside the container group and verify the container can read/write files on the share
- [ ] Build an `IContainerJobRunner` service: `SubmitJobAsync(image, command, envVars)` → returns a job ID; `GetJobStatusAsync(jobId)` → returns exit code + logs
- [ ] Expose the runner via a Minimal API endpoint: `POST /jobs` triggers a container; `GET /jobs/{id}` returns status
- [ ] Write a comparison document: ACI vs AKS Job vs Hangfire BackgroundJob — latency, cost, scaling, use cases
- [ ] Write an ADR for choosing ACI over AKS for ephemeral on-demand workloads

## Expected Output

An ASP.NET Core Minimal API that accepts job requests, provisions ACI containers on-demand, polls for completion, and returns logs — demonstrating the full ephemeral job runner pattern.
