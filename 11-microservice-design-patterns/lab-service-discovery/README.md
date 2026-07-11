# Lab: Service Discovery Pattern

## Objectives
- Let services locate each other's network location dynamically instead of relying on hardcoded hosts/ports.
- Implement client-side discovery (client queries a registry and picks an instance) and compare it with server-side discovery (a load balancer/gateway resolves the instance).
- Register and deregister service instances automatically as they scale up/down or fail health checks.
- Explain how service discovery interacts with load balancing and the [[lab-api-gateway]]/[[lab-circuit-breaker]] patterns in a real deployment.

## Key Concepts
`Service Discovery` · `Service Registry` · `Client-Side Discovery` · `Server-Side Discovery` · `Health Checks` · `DNS-Based Discovery`

## Tasks
- [ ] Stand up 2+ instances of the same backend service behind a service registry (e.g., Consul, Eureka, or Kubernetes DNS/Services).
- [ ] Implement client-side discovery: a calling service queries the registry directly and load-balances across returned instances.
- [ ] Implement server-side discovery: route the same calls through a proxy/load balancer that queries the registry on the caller's behalf.
- [ ] Configure health checks so an unhealthy instance is automatically deregistered and stops receiving traffic.
- [ ] Scale a service instance up/down and verify callers pick up the change without a redeploy or config change.
- [ ] Kill an instance mid-traffic and measure how long it takes for callers to stop routing to it.

## Expected Output
A demonstration where scaling a backend service (adding/removing instances) and killing an instance are both reflected in caller traffic within the health-check interval, with no hardcoded instance addresses anywhere in client configuration.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
