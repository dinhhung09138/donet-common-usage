# lab-di-advanced

## Objectives

- Use Scrutor for assembly scanning to eliminate repetitive `AddScoped<IFoo, Foo>()` registrations
- Implement the decorator pattern via DI without manually wrapping every registration
- Apply keyed services (.NET 8) to replace factory/dictionary patterns
- Diagnose and fix a captive dependency bug

## Tasks

- [ ] Install `Scrutor`; use `services.Scan(scan => scan.FromAssemblyOf<Program>().AddClasses(c => c.AssignableTo<IRepository>()).AsImplementedInterfaces().WithScopedLifetime())` to auto-register all repository implementations
- [ ] Demonstrate `AsSelf()` vs `AsImplementedInterfaces()` by registering a service both ways and resolving via interface and concrete type
- [ ] Implement a caching decorator `CachingProductRepository` that wraps `IProductRepository`; use `services.Decorate<IProductRepository, CachingProductRepository>()` to apply the decorator without touching existing code
- [ ] Register two payment processors (`StripePaymentProcessor`, `PayPalPaymentProcessor`) as keyed services with `.NET 8` `AddKeyedScoped<IPaymentProcessor, StripePaymentProcessor>("stripe")`; resolve by key using `IKeyedServiceProvider`
- [ ] Demonstrate a captive dependency bug: register a `SingletonService` that takes a scoped `DbContext` in the constructor; show the `ObjectDisposedException` or stale context; fix by injecting `IServiceScopeFactory` instead
- [ ] Write `IServiceCollection` extension methods to group related registrations (e.g., `services.AddPaymentInfrastructure()`, `services.AddEmailInfrastructure()`) for cleaner `Program.cs`
- [ ] Implement conditional registration: register `MockEmailSender` in Development and `SendGridEmailSender` in Production using `IHostEnvironment`
- [ ] Write unit tests confirming decorator intercepts calls and keyed services resolve the correct implementation

## Expected Output

A DI setup with Scrutor scanning, a working decorator, keyed services, a fixed captive dependency, and clean extension methods for module registration.

## Key Concepts Practiced

`Scrutor` · `Scan` · `AsImplementedInterfaces` · `Decorate<T>` · `AddKeyedSingleton/Scoped/Transient` · `IKeyedServiceProvider` · `captive dependency` · `IServiceScopeFactory` · `conditional registration`

## Status

- [ ] Lab completed
- [ ] PR description written → `src/05-technical-english/pr-descriptions/lab-di-advanced-pr.md`
