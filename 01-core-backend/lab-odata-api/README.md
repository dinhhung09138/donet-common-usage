# Lab: ASP.NET Core OData API

## Objectives
- Expose an ASP.NET Core Web API endpoint through OData, enabling clients to compose `$filter`, `$select`, `$expand`, `$orderby`, `$top`/`$skip` queries without bespoke query-parameter code.
- Build an Entity Data Model (EDM) that accurately reflects entity relationships and controls which properties/navigations are queryable.
- Apply guardrails (query-option validation, max page size, allowed expand depth) so OData's expressive query surface can't be abused for denial-of-service or data-exposure risk.
- Compare OData against a hand-rolled filtering/pagination API and GraphQL, and articulate when OData is the right fit for a senior/architect-level API design decision.

## Key Concepts
`EDM (Entity Data Model)` · `ODataModelBuilder` · `$filter` / `$select` / `$expand` / `$orderby` / `$top` / `$skip` · `[EnableQuery]` · `ODataQueryOptions` · `Query option validation settings` · `$count` · `OData routing conventions`

## Tasks
- [ ] Add `Microsoft.AspNetCore.OData` to a Web API project and build an EDM model (`ODataModelBuilder`) for at least two related entities (e.g. `Order` → `OrderItems`).
- [ ] Expose an OData-enabled controller/endpoint with `[EnableQuery]` and verify `$filter`, `$select`, and `$orderby` work against the entity set from the client.
- [ ] Verify `$expand` correctly returns the related navigation property (e.g. `Orders?$expand=OrderItems`) without triggering N+1 queries against the EF Core context.
- [ ] Configure `ODataQueryOptions`/validation settings to cap `$top`, restrict allowed `$expand` depth, and reject unsupported query options, preventing unbounded or overly expensive queries.
- [ ] Enable `$count=true` and verify the response includes the total matching record count alongside the page of results.
- [ ] Write an automated test that issues a combined query (`$filter` + `$select` + `$expand` + `$top`) and asserts the shape and correctness of the response.
- [ ] Document a short comparison of OData vs. a custom filtering DSL vs. GraphQL for this API's use case, including query-cost/security trade-offs.

## Expected Output
A running ASP.NET Core API exposing an OData entity set where combined `$filter`/`$select`/`$expand`/`$orderby`/`$top` queries return correctly shaped, correctly filtered JSON with an accurate `$count`, an oversized `$top` or disallowed `$expand` is rejected with a 400, and an automated test suite verifies the query behavior end-to-end.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
