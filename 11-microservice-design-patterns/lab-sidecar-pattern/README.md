# Lab: Sidecar Pattern

## Objectives
- Deploy a sidecar container alongside a main application container in the same Kubernetes pod to handle a cross-cutting concern.
- Explain how the sidecar pattern decouples infrastructure concerns (logging, proxying, TLS termination) from application code.
- Compare sidecar vs. in-process library approaches for solving the same cross-cutting concern.
- Configure shared resources (volume, localhost network) between the main container and sidecar.

## Key Concepts
`Sidecar Pattern` · `Kubernetes Pod` · `Service Mesh` · `Shared Volume` · `localhost Networking`

## Tasks
- [ ] Containerize a minimal .NET API as the main container.
- [ ] Add a sidecar container (e.g., a log-shipping agent or a lightweight reverse proxy) in the same pod spec.
- [ ] Configure a shared volume or `localhost` network so the sidecar can read app logs or intercept app traffic.
- [ ] Deploy the pod to a local Kubernetes cluster (kind/minikube/AKS) and verify both containers start and communicate.
- [ ] Kill the sidecar container and observe how the main app behaves (does it degrade gracefully or crash?).

## Expected Output
A running pod with two containers visible via `kubectl get pods`, plus log output or proxy behavior confirming the sidecar is intercepting/processing traffic or logs from the main container.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
