# Lab: Azure Functions

## Objectives

- Build Azure Functions with multiple trigger types
- Use managed identity instead of connection strings
- Deploy to Azure and monitor with Application Insights

## Tasks

- [ ] Create Function App project (.NET isolated worker)
- [ ] Implement HTTP trigger: process POST request, validate input, return 201/400
- [ ] Implement Timer trigger: run every 5 minutes, log execution
- [ ] Implement Service Bus trigger: consume messages, handle poison messages
- [ ] Configure managed identity for Service Bus access (no connection strings)
- [ ] Add Application Insights for telemetry
- [ ] Deploy to Azure using GitHub Actions
- [ ] Demonstrate cold start behavior (Consumption plan) vs warm (Premium plan)

## Expected Output

Deployed Function App with 3 trigger types, managed identity configured, telemetry visible in Application Insights.

## Key Concepts Practiced

`Azure Functions` · `Managed Identity` · `Triggers` · `Bindings` · `Cold start`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
