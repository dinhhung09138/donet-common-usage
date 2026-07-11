# Lab: MySQL with EF Core (Pomelo)

## Objectives

- Connect an ASP.NET Core API to MySQL using the Pomelo EF Core provider
- Understand MySQL-specific behaviours that differ from SQL Server
- Use MySQL JSON column type and full-text search

## Key Concepts

`Pomelo.EntityFrameworkCore.MySql` · `AUTO_INCREMENT` · `JSON column type` · `Full-text search` · `charset/collation` · `ONLY_FULL_GROUP_BY` · `Connection pooling`

## Tasks

- [ ] Install `Pomelo.EntityFrameworkCore.MySql` and configure `UseMySql` with server version detection
- [ ] Create and apply migrations — compare generated SQL vs SQL Server equivalent
- [ ] Demonstrate `AUTO_INCREMENT` gap behaviour under concurrent inserts vs SQL Server `IDENTITY`
- [ ] Map a `JSON` column using `HasColumnType("json")` and query inside it with `JSON_EXTRACT`
- [ ] Add a `FULLTEXT` index and use `MATCH ... AGAINST` via raw SQL
- [ ] Configure charset (`utf8mb4`) and collation (`utf8mb4_unicode_ci`) at model level
- [ ] Compare connection string options: `AllowUserVariables`, `Convert Zero Datetime`, pooling params

## Expected Output

A minimal ASP.NET Core API backed by MySQL, with migrations, a JSON column endpoint, and a full-text search endpoint.

## Implementation Walkthrough

_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting

_(to be filled in after completing the lab)_
