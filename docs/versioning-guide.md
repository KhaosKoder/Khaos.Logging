# Versioning Guide

## Overview

This solution uses **Semantic Versioning 2.0.0**, derives package versions from **Git tags**, and relies on **[MinVer](https://github.com/adamralph/minver)** to compute the effective version during every build. All packable projects (currently the `Khaos.Logging` package that bundles the runtime, generator, and analyzers) receive the **same version number** for a given commit. Git tags following the `Khaos.Logging/vX.Y.Z` pattern are the single source of truth for released versions.

## Semantic Versioning Rules

- **MAJOR** &mdash; increment when you introduce breaking changes to public APIs or behavioral contracts (for example, removing members from generated loggers or changing analyzer defaults).
- **MINOR** &mdash; increment when you add backwards-compatible functionality (new diagnostics, additional helper APIs, or optional configuration that does not break existing consumers).
- **PATCH** &mdash; increment for backwards-compatible bug fixes, performance improvements, or internal refactoring that does not alter the public surface.

Examples:

- Removing an existing generated logger property → `Khaos.Logging/v2.0.0`.
- Adding a new analyzer diagnostic that is disabled by default → `Khaos.Logging/v1.3.0`.
- Fixing an EventId calculation bug → `Khaos.Logging/v1.2.1`.

## Tagging and Releasing

1. Ensure the working tree is clean and all tests (including coverage generation) succeed:
   ```powershell
   dotnet test
   ```
2. Decide the next semantic version based on the rules above.
3. Create and push the tag using the required prefix:
   ```powershell
   git tag Khaos.Logging/v1.2.0
   git push origin Khaos.Logging/v1.2.0
   ```
4. Build the packages (MinVer will read the tag and stamp every packable project):
   ```powershell
   dotnet pack -c Release
   ```
5. Verify that all `.nupkg` files in `/artifacts` share the expected version (e.g., `1.2.0`).
6. Publish to NuGet.org or your internal feed using `dotnet nuget push` as needed.

## Pre-release and Development Builds

Commits after the most recent tag automatically receive pre-release versions such as `1.3.0-alpha.1`, `1.3.0-alpha.2`, etc. These builds are intended for internal validation and preview testing. Publish them only when you explicitly want to distribute preview packages.

## Do's and Don'ts

- **Do** change the version only by creating/pushing the appropriate Git tag.
- **Do** follow the SemVer rules when deciding MAJOR vs MINOR vs PATCH.
- **Do** run tests (with coverage) before tagging or publishing.
- **Don't** edit `<Version>`, `<AssemblyVersion>`, or related properties inside project files.
- **Don't** override MinVer properties in individual projects to “force” a version.
- If the wrong version was tagged, fix the Git tag (delete/recreate) instead of modifying project files.

## Cheat Sheet

| Scenario                                 | Tag example                  |
|------------------------------------------|------------------------------|
| Breaking API change                      | `Khaos.Logging/v2.0.0`       |
| Backwards-compatible feature addition    | `Khaos.Logging/v1.3.0`       |
| Bug fix / perf tweak                     | `Khaos.Logging/v1.2.1`       |

## Relation to Other Libraries

Khaos.Logging is part of a broader ecosystem, but its versioning is independent. Each solution and repository owns its own `Khaos.<Product>/vX.Y.Z` tag namespace. Downstream bundles or meta-packages should reference the desired ranges of this product explicitly.
