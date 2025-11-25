# Khaos.Logging User Guide

This guide walks you through installing the NuGet package, declaring log events, consuming the generated loggers, and understanding how the bundled documentation is copied into your solution.

## Installation

1. Add the package reference:
   ```bash
   dotnet add package Khaos.Logging
   ```
2. The runtime targets `net9.0` and brings the source generator + analyzer along for the ride, so no extra references are needed.
3. Restore your solution and build once so the generator can emit loggers for any enums already marked with `[LogEventSource]`.

## Defining Enum-Based Log Events

1. Create (or update) an enum that will represent all of your log events.
2. Annotate it with `Khaos.Logging.LogEventSourceAttribute`.
3. Follow the `AREA_Group_Action` naming convention so each enum member tokenizes cleanly.

```csharp
using Khaos.Logging;

namespace MyApp.Logging;

[LogEventSource(LoggerRootTypeName = "MyLogger", BasePath = "MyApp")]
public enum LogEventIds
{
    APP_Startup = 1000,
    APP_ReadConfiguration = 1001,
    DB_Connection_Open = 2000,
    DB_Connection_Close = 2001,
    DB_Pool_Timing_Measurement = 2002,
    DB_Pool_Timing_Count = 2003
}
```

### Attribute Options

- `LoggerRootTypeName`: Overrides the name of the generated root logger (defaults to `<EnumName>Logger`).
- `Namespace`: Forces generated types into a specific namespace instead of reusing the enum's namespace.
- `BasePath`: Prepends the event path (and thus `EventId.Name` + scope) with a prefix like `"MyApp"`.
- `Levels`: Reserved for future control over which log level methods are generated (currently all methods exist, but the property is honored for forward compatibility).

## Registering Generated Loggers

Call the generated extension in your DI configuration:

```csharp
builder.Services.AddLogging();
builder.Services.AddGeneratedLogging();
```

All generated loggers are registered as *scoped* generic services, so you can inject either the root logger or one of the area/group loggers:

```csharp
public sealed class OrderService
{
    private readonly MyLogger<OrderService> _log;

    public OrderService(MyLogger<OrderService> log)
    {
        _log = log;
    }

    public void Start()
    {
        _log.App.Startup.LogInformation("OrderService starting");
        _log.DB.Connection.Open.LogDebug("Opening DB for {OrderId}", 1234);
    }
}

public sealed class DbPoolService
{
    private readonly DbLogger<DbPoolService> _db;

    public DbPoolService(DbLogger<DbPoolService> db)
    {
        _db = db;
    }

    public void Probe()
    {
        _db.Pool.Timing.Measurement.LogInformation("Pool timing {DurationMs}", 42);
    }
}
```

## Event Metadata Behavior

- `EventId.Id` is always the raw numeric value of the enum member.
- `EventId.Name` equals the fully-qualified event path, e.g. `MyApp.DB.Connection.Open`.
- Each log call opens a scope with `EventPath = <event path>` so downstream sinks can filter or enrich based on that logical identifier.

## Analyzer Feedback

The included analyzers catch common mistakes:

- Duplicate numeric values (`KLG0001`, error).
- Applying `[LogEventSource]` to non-enums (`KLG0002`, error).
- Missing `_` separators or non-positive IDs (`KLG0003`/`KLG0004`, warnings).

Treat warnings as guidance for best practices; builds will fail on the errors.

## Documentation Copy Behavior

The NuGet package bundles the entire `docs/` directory and a build-transitive target named `Khaos.Logging.docs.targets`. When a consuming project restores the package:

- Before each build, the target copies the docs into `$(SolutionDir)docs\Khaos.Logging` (or `$(ProjectDir)docs\Khaos.Logging` if the solution directory is unavailable).
- To change the destination folder name, set the `KhaosLoggingDocsFolderName` MSBuild property in your project file:

  ```xml
  <PropertyGroup>
    <KhaosLoggingDocsFolderName>MyCompany.Logging</KhaosLoggingDocsFolderName>
  </PropertyGroup>
  ```

This creates an always-available set of docs inside the consumer solution without requiring manual steps.

## Quick Checklist

- [ ] Add/annotate your enum.
- [ ] Reference `Khaos.Logging` and rebuild once.
- [ ] Call `AddGeneratedLogging()` during DI setup.
- [ ] Inject the generated loggers and call the strongly-typed `IEventLogger` members.
- [ ] Use the copied docs under `docs/Khaos.Logging` for future reference.
