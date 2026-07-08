# lab-azure-queue-storage

## Objectives

- Enqueue, dequeue, peek, and delete messages using Azure Queue Storage SDK
- Understand visibility timeout as a distributed lock mechanism
- Implement a poison message handler using `DequeueCount`
- Decide when Queue Storage is sufficient vs when Service Bus is required

## Key Concepts

`QueueServiceClient` · `QueueClient` · `SendMessageAsync` · `ReceiveMessagesAsync` · `DeleteMessageAsync` · `VisibilityTimeout` · `DequeueCount` · `Poison message` · `Dead-letter queue` · `Approximate message count` · `Base64 encoding` · `Queue Storage vs Service Bus`

## Tasks

- [ ] Create a queue using `QueueServiceClient` and enqueue 10 messages with a payload (JSON object)
- [ ] Dequeue messages one at a time with a 30-second visibility timeout — simulate processing, then delete on success
- [ ] Simulate a processing failure: do not delete the message; verify it reappears after the visibility timeout expires
- [ ] Implement a poison message handler: after `DequeueCount >= 5`, move the message to a `<queue>-poison` queue and delete from the original
- [ ] Peek at messages without changing their visibility — verify count matches `GetPropertiesAsync().ApproximateMessagesCount`
- [ ] Enqueue a message with a 60-second delay (initial visibility timeout on send) — verify it is not visible immediately
- [ ] Build a background worker (`BackgroundService`) that continuously polls the queue and processes messages
- [ ] Write a comparison document: Queue Storage vs Service Bus — ordering, sessions, dead-letter, message size, throughput, cost, when to use each

## Expected Output

A console application demonstrating all queue operations and a `BackgroundService` worker, plus a written comparison in `docs/queue-vs-servicebus.md`.
