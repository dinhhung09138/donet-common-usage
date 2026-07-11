# Lab: MassTransit with RabbitMQ

## Objectives

- Design asynchronous, message-driven communication between services using MassTransit over RabbitMQ
- Define versioned message contracts as the stable API surface between producer and consumer
- Configure retry, redelivery, and error-queue policies so transient failures don't cause message loss
- Implement consumers that are idempotent and safe to reprocess after a redelivery
- Diagnose message flow using the RabbitMQ management UI and MassTransit's built-in diagnostics

## Key Concepts

`MassTransit` · `IBus` / `IPublishEndpoint` · `IConsumer<T>` · `Message contract` · `Exchange/Queue/Binding` · `Retry policy` · `Redelivery` · `Error queue` · `Dead-letter queue` · `Correlation ID` · `Idempotent consumer` · `Saga` (overview)

## Tasks

- [ ] Add MassTransit + RabbitMQ transport to an ASP.NET Core project (`AddMassTransit`, `UsingRabbitMq`)
- [ ] Define a message contract (e.g., `OrderPlaced`) as an immutable record in a shared contracts project
- [ ] Implement a publisher endpoint that publishes the message via `IPublishEndpoint` after a business action
- [ ] Implement a `IConsumer<OrderPlaced>` in a separate worker/service and verify end-to-end delivery
- [ ] Configure a retry policy (`UseMessageRetry`) with exponential backoff for transient consumer failures
- [ ] Configure second-level retry / redelivery (`UseScheduledRedelivery`) and observe the difference from immediate retry
- [ ] Force a poison message and verify it lands in the `_error` queue after retries are exhausted
- [ ] Make the consumer idempotent (e.g., dedupe by message ID) and prove a redelivered message doesn't double-process
- [ ] Inspect exchanges, queues, and bindings MassTransit auto-provisions in the RabbitMQ management UI
- [ ] Write an integration test using the in-memory test harness (`ITestHarness`) to assert publish/consume without a real broker

## Expected Output

A producer service and a consumer service running against a local RabbitMQ broker (Docker), with a message published from the producer reliably consumed by the worker. A deliberately failing message ends up in the error queue after configured retries, and the management UI shows the auto-provisioned topology.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
