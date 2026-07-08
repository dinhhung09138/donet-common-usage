# Lab: Service Bus Patterns

## Objectives

- Implement reliable message publishing and consumption with Azure Service Bus
- Handle failure scenarios: retries, dead letter queue, poison messages
- Ensure idempotent message processing

## Tasks

- [ ] Create Service Bus namespace with a queue and a topic+subscription
- [ ] Implement producer: send single message, send batch, schedule message
- [ ] Implement consumer: process messages, acknowledge, abandon
- [ ] Configure max delivery count and dead letter queue
- [ ] Implement dead letter queue processor (monitor + alert)
- [ ] Implement idempotent consumer using message ID deduplication
- [ ] Demonstrate topic+subscription fan-out pattern
- [ ] Use managed identity for all auth

## Expected Output

Producer + consumer working end-to-end. DLQ demo showing what happens after max retries. Idempotency test.

## Key Concepts Practiced

`Service Bus` · `Dead letter queue` · `Idempotency` · `Fan-out` · `Message sessions`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
