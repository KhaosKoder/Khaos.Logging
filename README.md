# Khaos.Logging

Typed, discoverable logging built on top of `Microsoft.Extensions.Logging`. Khaos.Logging lets you describe every loggable event once—as an enum—and generates a fully navigable logger surface so you can write `_log.DB.Connection.Open.LogInformation("Opening connection")` without manually wiring scopes, event IDs, or categories.

## Why Another Logging Layer?

`ILogger` is flexible, but large applications end up with stringly-typed event IDs, ad-hoc scopes, and no shared vocabulary. We wanted:

- A single source of truth for events (enums) that doubles as documentation.
- Automatic, hierarchical loggers that mirror your domain while preserving `ILogger<T>` categories.
- Guardrails: analyzers that catch duplicate IDs, naming mistakes, or invalid values.
- Zero runtime reflection and no magic DI setup—everything compiles ahead of time.

Khaos.Logging keeps `ILogger` in the picture; it simply builds strongly-typed façades over it so your team can reason about events the same way they reason about APIs.

## How It Works

1. Annotate an enum with `[LogEventSource]` and follow the `AREA_Group_Action` naming convention.
2. The incremental source generator emits:
	- A root logger (customizable name) and nested loggers for each area/group token.
	- `IEventLogger` properties per enum member, prewired with `EventId` and an `EventPath` scope.
	- A DI extension `AddGeneratedLogging()` registering everything as scoped generics.
3. The runtime provides the lightweight `EventLogger` implementation and attribute definitions.
4. The analyzer project enforces duplicate-ID detection, naming guidance, and other correctness checks.

## Quick Start

1. **Install the package**
	```powershell
	dotnet add package Khaos.Logging
	```
2. **Declare your log events**
	```csharp
	using Khaos.Logging;

	namespace MyApp.Logging;

	[LogEventSource(LoggerRootTypeName = "MyLogger", BasePath = "MyApp")]
	public enum LogEventIds
	{
		 APP_Startup = 1000,
		 APP_ReadConfiguration = 1001,
		 DB_Connection_Open = 2000,
		 DB_Connection_Close = 2001
	}
	```
3. **Register generated loggers**
	```csharp
	builder.Services.AddLogging();
	builder.Services.AddGeneratedLogging();
	```
4. **Inject and use**
	```csharp
	public sealed class StartupService
	{
		 private readonly MyLogger<StartupService> _log;

		 public StartupService(MyLogger<StartupService> log) => _log = log;

		 public void Start()
		 {
			  _log.App.Startup.LogInformation("StartupService online");
			  _log.DB.Connection.Open.LogDebug("Opening DB for {Tenant}", "Contoso");
		 }
	}
	```

Generated loggers always respect `ILogger<T>` categories, emit scopes with `EventPath = "MyApp.DB.Connection.Open"`, and keep the enum value wired to `EventId.Id`. You can still inject a plain `ILogger<T>` anywhere—it remains the same DI container and the two coexist without adapters.

## FAQ: Why Not Just Use ILogger?

You absolutely can (and still do). Khaos.Logging is a layer **on top of** `ILogger` that eliminates repetitive plumbing:

- **Discoverability**: Instead of searching for numeric IDs or message templates, IDE completion guides you through areas/groups/actions.
- **Consistency**: Event IDs, names, and scopes are generated from the enum, so they cannot drift.
- **Safety nets**: The analyzers fail the build if you accidentally duplicate IDs or misapply attributes.

When a dependency expects `ILogger` you keep supplying `ILogger`; generated loggers internally use the same `ILogger<T>` instances, so you can mix and match without wrappers. Think of the generated APIs as purpose-built entry points into the existing logging infrastructure, not a replacement.

## Design Principles

- **Enums as contracts**: Everything—EventId, scope metadata, documentation—derives from the annotated enum.
- **Hierarchical surface**: Area/group/action tokens become nested types, mirroring the shape of your domain.
- **No runtime surprises**: All code is generated at build time; DI registration is explicit and scoped.
- **Documentation included**: The NuGet ships the `docs/` folder plus build-transitive targets that copy it into consuming solutions for easy reference.

## Documentation

- [Specification](docs/Specification.md) – end-to-end, low-level requirements.
- [User Guide](docs/user-guide.md) – installation, configuration, and day-to-day usage tips.
- [Developer Guide](docs/developer-guide.md) – repo layout, build/test workflow, release checklist.
- [Versioning Guide](docs/versioning-guide.md) – explains MinVer tagging conventions and release numbering.
- [Scripts Reference](docs/scripts.md) – details each helper script, parameters, and expected output.

Explore the guides, run `scripts/test-with-coverage.ps1`, and open `TestResults/.../coverage-html/index.html` to see test coverage while you iterate. When you're ready to publish, `scripts/publish.ps1 -ApiKey <token>` handles packing and pushing both the runtime and symbol packages.
