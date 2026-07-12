# Lab: AutoMapper

## Objectives
- Author `Profile` classes that define explicit, testable entity-to-DTO and DTO-to-entity mappings instead of ad-hoc manual mapping code scattered across services.
- Configure custom member mappings, value resolvers, and type converters for cases where convention-based mapping is insufficient (flattening, computed fields, enum translation).
- Use `ProjectTo<T>` for EF Core `IQueryable` projection to push mapping into the SQL query instead of materializing full entities, a meaningful performance consideration at scale.
- Validate mapping configuration at startup (`AssertConfigurationIsValid`) so mapping mismatches fail fast in CI rather than surfacing as runtime bugs.

## Key Concepts
`Profile` · `CreateMap` · `ForMember` · `IValueResolver` · `ITypeConverter` · `ProjectTo<T>` · `IQueryable` projection · `AssertConfigurationIsValid` · Reverse mapping

## Tasks
- [ ] Define an entity model and corresponding read/write DTOs (e.g. `Order` entity vs. `OrderDto`/`CreateOrderDto`) with at least one field that doesn't map 1:1 by name.
- [ ] Author an AutoMapper `Profile` with `CreateMap` calls, using `ForMember` to resolve the non-trivial field (e.g. flattening `Customer.Name` into `OrderDto.CustomerName`).
- [ ] Implement a custom `IValueResolver` or `ITypeConverter` for a case requiring external logic (e.g. computing `OrderDto.TotalWithTax` from multiple entity fields).
- [ ] Use `ProjectTo<OrderDto>(configuration)` against an EF Core `IQueryable<Order>` and confirm (via logged SQL) that only the projected columns are selected.
- [ ] Register AutoMapper in DI (`AddAutoMapper`) and call `AssertConfigurationIsValid()` in a startup/unit test to catch unmapped or misconfigured members.
- [ ] Write unit tests for the mapping profile in isolation (not through a controller) covering the custom resolver and reverse mapping if used.

## Expected Output
A working .NET project with an AutoMapper profile mapping entities to DTOs, a `ProjectTo<T>` query against EF Core whose generated SQL selects only the mapped columns, a passing `AssertConfigurationIsValid()` check, and unit tests covering the custom value resolver.

## Implementation Walkthrough

Step-by-step, in the order it was actually built. Follow along against the source under `src/LabAutoMapper/` and `tests/LabAutoMapper.Tests/` — each step names the exact file(s) it produces.

### 1. Scaffold the solution and projects

```bash
dotnet new sln -n LabAutoMapper
dotnet new console -n LabAutoMapper -o src/LabAutoMapper --framework net8.0
dotnet new xunit -n LabAutoMapper.Tests -o tests/LabAutoMapper.Tests --framework net8.0
dotnet sln add src/LabAutoMapper/LabAutoMapper.csproj tests/LabAutoMapper.Tests/LabAutoMapper.Tests.csproj
dotnet add tests/LabAutoMapper.Tests/LabAutoMapper.Tests.csproj reference src/LabAutoMapper/LabAutoMapper.csproj
```

Requires the .NET 8 SDK (`dotnet --list-sdks` must list an `8.x` entry).

### 2. Add NuGet packages

Version pins matter: the latest `AutoMapper` and `Microsoft.EntityFrameworkCore.Sqlite` releases at time of writing target `net10.0` and fail to restore against `net8.0` with `NU1202` if you don't pin.

`src/LabAutoMapper/LabAutoMapper.csproj`:

```bash
dotnet add src/LabAutoMapper package AutoMapper                                          # resolved to 16.2.0
dotnet add src/LabAutoMapper package Microsoft.EntityFrameworkCore.Sqlite --version 8.0.11
dotnet add src/LabAutoMapper package Microsoft.Extensions.DependencyInjection --version 8.0.1
dotnet add src/LabAutoMapper package Microsoft.Extensions.Logging.Console --version 8.0.1
```

`tests/LabAutoMapper.Tests/LabAutoMapper.Tests.csproj`:

```bash
dotnet add tests/LabAutoMapper.Tests package Microsoft.EntityFrameworkCore.Sqlite --version 8.0.11
```

(`xunit`, `xunit.runner.visualstudio`, `Microsoft.NET.Test.Sdk` come from the `dotnet new xunit` template — no separate install needed.)

### 3. Domain model (`Domain/`)

Write in this order — each file depends on the one before it:

1. `OrderStatus.cs` — plain enum, no dependencies.
2. `Customer.cs` — references `Order` only via a `List<Order>` navigation.
3. `Order.cs` — references `Customer` and `OrderStatus`. Includes `InternalNotes`, a field **intentionally never mapped** to any DTO — this is what later proves `ProjectTo` prunes unselected columns.

### 4. DTOs (`Dtos/`)

1. `OrderDto.cs` — the read model (`CustomerName`, `TotalWithTax`, `Status` as `string`).
2. `CreateOrderDto.cs` — the write model, references `OrderStatus`.

### 5. Mapping layer (`Mapping/`)

Build bottom-up so each file compiles against what already exists:

1. `ITaxRateProvider.cs` — interface + `FlatTaxRateProvider` implementation + a `TaxRates.FlatRate` constant shared by both the resolver and the profile's expression-based mapping (keeps the two consistent without duplicating the tax rate).
2. `TotalWithTaxResolver.cs` — `IValueResolver<Order, OrderDto, decimal>`, constructor-injects `ITaxRateProvider`.
3. `OrderStatusToStringConverter.cs` — `ITypeConverter<OrderStatus, string>`.
4. `OrderProfile.cs` — the `Profile` that ties it together:
   - `CreateMap<OrderStatus, string>().ConvertUsing<OrderStatusToStringConverter>()` — registered for standalone enum→string mapping (exercised directly in tests), **not** used on `OrderDto.Status` (see Common Pitfalls for why).
   - `CreateMap<Order, OrderDto>()` with `.ForMember(CustomerName, MapFrom(src => src.Customer.Name))` (flattening), `.ForMember(TotalWithTax, MapFrom(src => src.Subtotal * (1 + TaxRates.FlatRate)))`, `.ForMember(Status, MapFrom(src => src.Status.ToString()))` — all three are plain expressions so this map stays usable by `ProjectTo`.
   - `CreateMap<CreateOrderDto, Order>()` with `.ForMember(Id, Ignore())`, `.ForMember(Customer, Ignore())`, `.ForMember(InternalNotes, Ignore())` — required or `AssertConfigurationIsValid()` fails (see Common Pitfalls).

### 6. Data layer (`Data/`)

1. `AppDbContext.cs` — `DbSet<Customer>`, `DbSet<Order>`, `OnModelCreating` wires the `Order.Customer` FK.
2. `SeedData.cs` — a static `Seed(AppDbContext)` helper adding one `Customer` and two `Order`s.

### 7. `Program.cs` — wiring order matters

1. Open a `SqliteConnection("DataSource=:memory:")` **before** building the `DbContext`, and keep it open for the process lifetime — SQLite's `:memory:` database is destroyed the instant the connection closes, so the DI-registered options must reuse this exact connection instance.
2. `services.AddLogging(...)` with a console provider and a filter on category `Microsoft.EntityFrameworkCore.Database.Command` set to `LogLevel.Information` — this is what makes EF Core print generated SQL to the console.
3. `services.AddDbContext<AppDbContext>((provider, options) => options.UseSqlite(connection).UseLoggerFactory(provider.GetRequiredService<ILoggerFactory>()))` — pulling the logger factory from the same `provider` routes EF Core's SQL logging into the console sink registered in step 2.
4. `services.AddSingleton<ITaxRateProvider, FlatTaxRateProvider>()`.
5. `services.AddAutoMapper(cfg => { }, typeof(OrderProfile))` — registers `IMapper` and scans the assembly containing `OrderProfile`.
6. Build the service provider, resolve `AppDbContext`, call `Database.EnsureCreated()`, then `SeedData.Seed(dbContext)`.
7. Resolve `IMapper`, call `mapper.ConfigurationProvider.AssertConfigurationIsValid()` — must run **after** the provider is built, since it needs the fully composed `MapperConfiguration`.
8. `dbContext.Orders.ProjectTo<OrderDto>(mapper.ConfigurationProvider).ToList()` — the console log line printed immediately before this call's results is the generated `SELECT`.

### 8. Verify

```bash
dotnet build LabAutoMapper.sln
dotnet run --project src/LabAutoMapper
dotnet test
```

`dotnet run` prints the generated SQL:

```sql
SELECT "o"."Id", "c"."Name", "o"."Subtotal", "o"."Status", ef_multiply("o"."Subtotal", '1.1')
FROM "Orders" AS "o"
INNER JOIN "Customers" AS "c" ON "o"."CustomerId" = "c"."Id"
```

`InternalNotes` and the raw `CustomerId` are never selected — only the columns `OrderDto` actually needs, plus the JOIN pushed down for the flattened `CustomerName`.

### 9. Tests (`tests/LabAutoMapper.Tests/`)

- `OrderProfileTests.cs` — `AssertConfigurationIsValid()`, `CustomerName` flattening, `TotalWithTax` computation, `OrderStatus → string` conversion, `CreateOrderDto → Order` reverse/write mapping, and `TotalWithTaxResolver` both in isolation (direct `.Resolve(...)` call) and running through a standalone `MapperConfiguration` with DI wired via `cfg.ConstructServicesUsing(provider.GetService!)` plus `services.AddTransient<TotalWithTaxResolver>()`.
- `ProjectToSqlTests.cs` — builds its own SQLite in-memory `AppDbContext` with `LogTo` capturing SQL into a `StringBuilder`, runs the same `ProjectTo<OrderDto>` query, and asserts the captured text contains the mapped columns and excludes `InternalNotes`.

## Common Pitfalls & Troubleshooting

- **`IValueResolver`/`ITypeConverter` and `ProjectTo` don't mix.** The original design put `TotalWithTax` behind `MapFrom<TotalWithTaxResolver>()` and `Status` behind the `OrderStatus → string` `ITypeConverter`, using the *same* `OrderDto` for both `mapper.Map()` and `ProjectTo<OrderDto>()`. Building an `IQueryable` projection requires an expression tree AutoMapper can pass to EF Core; a resolver's `Resolve(...)` method and a converter's `Convert(...)` method are arbitrary C# code, not expressions, so `ProjectTo` cannot inline them. This failed in two distinct ways:
  - The type converter attempt threw `System.ArgumentException: Type 'System.String' does not have a default constructor` — AutoMapper tried to build a `new String()` expression as part of translating the converter.
  - The resolver attempt threw `AutoMapperMappingException: Unable to create a map expression from ... to Decimal.TotalWithTax`.

  **Fix**: for members that need to survive `ProjectTo`, use a translatable `MapFrom(src => ...)` expression instead (e.g. `src.Subtotal * (1 + TaxRates.FlatRate)` and `src.Status.ToString()`). Reserve `IValueResolver`/`ITypeConverter` for mappings that only ever go through `mapper.Map()` on already-materialized objects — that's exactly the "meaningful performance consideration at scale" the Objectives call out: know which of your DTO members can be pushed into SQL and which can't, and design the profile (or split into two DTOs) accordingly rather than discovering it in production.

- **`CreateMap<TSource, TDestination>()` doesn't auto-ignore reverse-direction-only members.** `CreateMap<CreateOrderDto, Order>()` initially failed `AssertConfigurationIsValid()` with "Unmapped properties: Id, Customer, InternalNotes" — properties that exist on `Order` but have no counterpart on the write DTO. Each had to be `.ForMember(dest => dest.X, opt => opt.Ignore())` explicitly; AutoMapper does not infer "this is a write-only DTO, skip whatever it doesn't mention."

- **A custom resolver with constructor-injected dependencies must be registered with the DI container **in addition** to calling `cfg.ConstructServicesUsing(provider.GetService!)`.** Registering only `ITaxRateProvider` in the `ServiceCollection` and expecting AutoMapper to construct `TotalWithTaxResolver` (which depends on it) threw `Cannot create an instance of type LabAutoMapper.Mapping.TotalWithTaxResolver`. The resolver class itself also needs a DI registration (`services.AddTransient<TotalWithTaxResolver>()`) so the container knows how to build it, not just its dependency.

- **`MapperConfiguration`'s constructor signature changed in AutoMapper 16.x** — it now requires an `ILoggerFactory` argument (`NullLoggerFactory.Instance` works fine when you don't care about AutoMapper's internal logging). Also note: AutoMapper 13+ is a commercially licensed product for production use (Lucky Penny Software); development/test usage prints a one-time console warning but works without a license key, which is fine for a lab but worth knowing before reaching for the latest major version in a real project.

- **EF Core InMemory provider is the wrong choice for this lab.** It never generates SQL text at all, so there's nothing to log or assert on for the "only projected columns are selected" requirement. SQLite with an open in-memory connection (`DataSource=:memory:`, connection kept open for the `DbContext`'s lifetime) is the lightest real SQL engine that still produces inspectable, real `SELECT` statements via `LogTo`.
