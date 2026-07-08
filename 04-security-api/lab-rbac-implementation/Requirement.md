# Lab: RBAC — Policy-Based Authorization

## Objectives

- Implement role-based access control using ASP.NET Core's policy system
- Implement resource-based authorization (owner can edit their own resources)
- Implement claim-based authorization for fine-grained permissions

## Tasks

- [ ] Define roles: Admin, Manager, User
- [ ] Define permissions as claims: `orders:read`, `orders:write`, `reports:read`
- [ ] Implement `IAuthorizationRequirement` + `IAuthorizationHandler` for each permission
- [ ] Register policies: `CanWriteOrders`, `CanReadReports`
- [ ] Apply `[Authorize(Policy = "CanWriteOrders")]` to endpoints
- [ ] Implement resource-based auth: user can only edit their own orders
- [ ] Implement `IAuthorizationHandler<ResourceOwnerRequirement>` with resource parameter
- [ ] Write tests: verify each role gets correct access (accepted + rejected)

## Expected Output

API with 3 roles, permission claims, and resource-based auth. Test matrix shows role vs permission access table.

## Key Concepts Practiced

`RBAC` · `Policy-based auth` · `IAuthorizationRequirement` · `Resource-based auth` · `Claims`

## Status

- [ ] Completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/`
