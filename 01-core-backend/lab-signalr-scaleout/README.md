# Lab: SignalR Scale-Out with a Backplane

## Objectives
- Explain why a single-instance SignalR hub breaks under horizontal scaling and design a scale-out topology using a backplane.
- Configure a Redis backplane (`Microsoft.AspNetCore.SignalR.StackExchangeRedis`) so messages broadcast from one server instance reach clients connected to any instance.
- Evaluate the trade-offs between a self-managed Redis backplane and Azure SignalR Service for a multi-tenant SaaS deployed on AKS.
- Verify cross-instance message delivery and sticky-session behavior under a load balancer.

## Key Concepts
`Backplane` · `Redis pub/sub` · `StackExchangeRedis SignalR backend` · `Azure SignalR Service` · `Sticky sessions / session affinity` · `Horizontal scaling` · `Connection state per instance` · `Multi-instance broadcast`

## Tasks
- [ ] Run two instances of the SignalR hub app (from `lab-signalr-hubs`) behind a reverse proxy/load balancer without a backplane and demonstrate the failure: a client connected to instance A never receives a broadcast triggered on instance B.
- [ ] Add a Redis container and wire `AddStackExchangeRedis(...)` into the SignalR server builder on both instances.
- [ ] Re-run the two-instance test and verify a broadcast issued on instance A now reaches a client connected to instance B via the Redis backplane.
- [ ] Configure the load balancer/reverse proxy (e.g. YARP or nginx) with sticky sessions and explain why SignalR requires affinity for non-WebSocket transports.
- [ ] Swap the Redis backplane for Azure SignalR Service in "Default" (or "Serverless") mode and compare configuration effort, cost model, and operational ownership vs. self-hosted Redis.
- [ ] Document a scale-out architecture decision (ADR-style) for a multi-tenant AKS deployment: backplane choice, sticky-session strategy, and failure-mode handling if Redis/Azure SignalR is unavailable.

## Expected Output
Two running instances of the hub application sharing one Redis backplane, with a demonstrated test showing a message broadcast on one instance is delivered to a client connected to the other instance — plus a short written comparison (ADR or table) of Redis backplane vs. Azure SignalR Service for production use.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
