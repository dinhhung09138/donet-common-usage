# System Design Practice Problems

Written design documents in English — practice for Toptal and senior-level interviews.

## Format

Each design document follows this structure:

1. **Requirements** — functional and non-functional
2. **Capacity estimation** — requests/sec, storage, bandwidth
3. **High-level design** — diagram + component description
4. **Detailed design** — data model, APIs, key algorithms
5. **Trade-offs** — what was chosen and why, what was left out
6. **Failure scenarios** — how the system handles failures

---

## Problems

| File | Problem | Difficulty |
|------|---------|------------|
| `url-shortener.md` | Design a URL shortener (like bit.ly) — 100M URLs, 10B reads/day | Medium |
| `notification-service.md` | Design a multi-channel notification service (email, push, SMS) | Medium |
| `job-queue.md` | Design a distributed job queue with priorities and retries | Medium-Hard |
| `chat-system.md` | Design a real-time chat system (1:1 and group) | Hard |
| `rate-limiter.md` | Design a distributed rate limiter as a standalone service | Medium |

---

## Toptal Interview Notes

Toptal's system design round is **2 hours, live, in English**. You will be asked to:

- Draw the architecture on a whiteboard/diagram tool
- Explain trade-offs clearly ("I chose X over Y because...")
- Handle follow-up questions ("What happens if the cache goes down?")
- Estimate scale ("How many servers do you need?")

**Study resources:**
- Grokking the System Design Interview (Educative)
- ByteByteGo by Alex Xu (book + YouTube)
