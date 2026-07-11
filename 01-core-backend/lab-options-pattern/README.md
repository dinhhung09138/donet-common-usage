# Lab: Options Pattern — IOptions, IOptionsSnapshot, IOptionsMonitor

## Objectives
- Master the differences between `IOptions`, `IOptionsSnapshot`, and `IOptionsMonitor` and know when to use each
- Implement startup validation so a misconfigured deployment fails fast with a clear error
- Use named options to handle multiple instances of the same configuration type
- Apply `PostConfigure` for cross-cutting overrides (e.g., environment-specific adjustments)

## Key Concepts
`IOptions<T>` · `IOptionsSnapshot<T>` · `IOptionsMonitor<T>` · `named options` · `IValidateOptions<T>` · `ValidateOnStart` · `ValidateDataAnnotations` · `PostConfigure`

## Tasks
- [ ] Create `SmtpOptions` POCO; bind it from `appsettings.json` using `services.Configure<SmtpOptions>(configuration.GetSection("Smtp"))`
- [ ] Inject `IOptions<SmtpOptions>` into a singleton service and `IOptionsSnapshot<SmtpOptions>` into a scoped service; demonstrate that snapshot picks up config file changes at request boundaries while `IOptions` does not
- [ ] Inject `IOptionsMonitor<SmtpOptions>` into a background service; use the `OnChange` callback to react to configuration changes without restart
- [ ] Define two named SMTP configurations (`"Primary"` and `"Fallback"`); inject `IOptionsSnapshot<SmtpOptions>` and resolve by name with `.Get("Primary")`
- [ ] Implement `IValidateOptions<SmtpOptions>` to validate that `Host` is not empty and `Port` is in range 1–65535; register with `services.AddSingleton<IValidateOptions<SmtpOptions>, SmtpOptionsValidator>()`
- [ ] Add `ValidateDataAnnotations()` and `ValidateOnStart()` to the options registration; verify the app throws on startup with an invalid config
- [ ] Use `PostConfigure<SmtpOptions>` to override `UseSsl = true` when `ASPNETCORE_ENVIRONMENT == "Production"` regardless of config file value
- [ ] Write unit tests for `SmtpOptionsValidator` and integration tests confirming startup failure on invalid options

## Expected Output
A working configuration setup with all three `IOptions` variants, named options, startup validation, `PostConfigure` override, and passing unit tests for the validator.

## Implementation Walkthrough
_(to be filled in after completing the lab)_

## Common Pitfalls & Troubleshooting
_(to be filled in after completing the lab)_
