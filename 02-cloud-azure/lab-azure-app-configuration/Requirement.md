# lab-azure-app-configuration

## Objectives

- Set up Azure App Configuration as a configuration provider in ASP.NET Core
- Use hierarchical keys and labels for environment-based isolation
- Reference Key Vault secrets from App Configuration without storing secret values
- Implement dynamic refresh with a sentinel key to avoid polling on every key
- Understand the difference between this lab and `lab-feature-flags-azure-appconfig`

## Key Concepts

`IConfiguration` · `.UseAzureAppConfiguration()` · `AzureAppConfigurationOptions` · `Hierarchical keys` · `Labels (dev/staging/prod)` · `Key Vault reference` · `IConfigurationRefresher` · `Sentinel key` · `CacheExpirationInterval` · `Snapshot` · `DefaultAzureCredential` · `Prefix filtering` · `ConfigureRefresh`

## Tasks

- [ ] Provision an Azure App Configuration store and add hierarchical keys (`App:Database:ConnectionString`, `App:Api:Timeout`) for `dev` and `prod` labels
- [ ] Register App Configuration as a provider in `Program.cs` using `AddAzureAppConfiguration` with `DefaultAzureCredential`
- [ ] Filter keys by prefix (`App:`) so only relevant config is loaded into `IConfiguration`
- [ ] Add a label (`dev`) to the provider options — verify that prod keys are not loaded in dev environment
- [ ] Add a Key Vault reference: store only the Key Vault URI in App Config, resolve the actual secret at runtime without code changes
- [ ] Configure `ConfigureRefresh` with a `CacheExpirationInterval` of 30 seconds and a sentinel key (`App:Sentinel`)
- [ ] Update a config value in the portal, then change the sentinel key — verify the running app picks up the change within the cache interval
- [ ] Inject `IConfigurationRefresher` and call `TryRefreshAsync()` manually from a health-check endpoint
- [ ] Take an App Configuration snapshot (point-in-time config) and explain when this is useful for deployments
- [ ] Write an ADR: when to use Azure App Configuration vs `appsettings.json` vs Azure Key Vault

## Expected Output

An ASP.NET Core API that reads all config from Azure App Configuration (no secrets in `appsettings.json`), dynamically refreshes on sentinel key change, and resolves Key Vault secrets transparently.
