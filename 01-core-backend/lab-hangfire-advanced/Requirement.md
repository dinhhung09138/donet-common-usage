# lab-hangfire-advanced

## Objectives

- Use Hangfire batch jobs and continuations for multi-step workflows
- Implement custom client and server filters for cross-cutting concerns
- Configure Hangfire with PostgreSQL storage and multi-server setup

## Key Concepts

`Batch` · `BatchContinuation` · `IClientFilter` · `IServerFilter` · `IApplyStateFilter` · `PostgreSQL storage` · `Multi-server` · `Job prioritization` · `Queue routing` · `Distributed lock`

## Tasks

- [ ] Create a batch of parallel jobs (e.g., send 100 emails in parallel) using `BatchJob.StartNew`
- [ ] Chain a continuation job that runs only after all batch jobs succeed
- [ ] Implement `IClientFilter` to inject a correlation ID into job parameters before enqueue
- [ ] Implement `IServerFilter` to log job duration and outcome to structured logs
- [ ] Configure `Hangfire.PostgreSql` as the backing store (replace default SQL Server)
- [ ] Run two Hangfire server instances pointing to the same storage; verify only one processes each job
- [ ] Assign jobs to named queues (`critical`, `default`, `low`) and configure server queue priority
- [ ] Implement `IApplyStateFilter` to send an alert when a job moves to the `Failed` state

## Expected Output

An ASP.NET Core host with two Hangfire server instances (same DB), demonstrating batch workflows, queue routing, and custom filter logging — with no duplicate job execution.
