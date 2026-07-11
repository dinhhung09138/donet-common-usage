# Lab: Query Optimization

## Objectives

- Identify slow queries using execution plans and EF Core logging
- Apply indexing strategies to improve read performance
- Eliminate N+1 problems with eager loading and projections
- Measure before/after performance with benchmarks

## Key Concepts

`Index strategy` · `EXPLAIN ANALYZE` · `N+1` · `Compiled queries` · `BenchmarkDotNet`

## Tasks

- [ ] Seed database with realistic dataset (10k+ rows)
- [ ] Write intentionally slow queries (full table scan, N+1, missing index)
- [ ] Enable EF Core query logging + slow query threshold
- [ ] Use `EXPLAIN ANALYZE` in PostgreSQL to understand execution plans
- [ ] Add appropriate indexes (composite, covering, partial)
- [ ] Refactor N+1 to use `.Include()` or `SELECT` projection
- [ ] Replace LINQ queries with compiled queries where applicable
- [ ] Use BenchmarkDotNet to measure improvement

## Expected Output

Side-by-side comparison: slow vs optimized queries with execution plans and benchmark results in README.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
