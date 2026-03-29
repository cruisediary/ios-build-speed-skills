# modular-architecture

Analyzes your Xcode project structure and guides decomposition into Swift Package Manager modules to enable true incremental builds.

## TRIGGER

Invocation: `/modular-architecture`
Description: Analyze project structure and guide SPM module decomposition for faster incremental builds.

## ENVIRONMENT

Follow `skills/core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

Detect project structure:
- Count targets in the project (look for `/* Begin PBXNativeTarget section */` in `project.pbxproj`, or list targets in `Package.swift`)
- Count source files per target
- Check for existing `Package.swift` at root

## AUDIT

Analyze for these patterns:

**1. Monolithic app target**
- Single app target contains more than 100 source files
- All feature code, networking, storage, and UI in the same target
- Symptom: touching any file recompiles a large portion of the project

**2. No module boundaries**
- `Package.swift` does not exist, or defines only one library target
- All app code imports the same root module

**3. Circular or overly broad import graphs**
- Look for `import ModuleName` in source files
- If almost all files import a central module that also imports feature modules, there is likely a circular dependency risk

**4. Feature code co-located with infrastructure**
- Files named `*Service.swift`, `*Repository.swift`, `*Manager.swift` mixed with `*View.swift`, `*ViewController.swift` in the same target directory

Collect findings from all four patterns.

## REPORT

Follow `skills/core/report-formatter.md` format.

```
🔴 [Critical] Monolithic app target: 347 source files in AppTarget
Impact:         Any change to a shared file triggers recompilation of most of the project
Recommendation: Decompose into feature modules (FeatureA, FeatureB) + a shared Core module
Example:        examples/modular-architecture/

🟡 [Medium] No Package.swift found — project uses single-target .xcodeproj
Impact:         Without module boundaries, the build system cannot cache unchanged modules
Recommendation: Introduce a Package.swift with at minimum a Core module and one feature module
Example:        examples/modular-architecture/
```

## ACTION

Mode: `guided`

This skill produces a step-by-step migration guide. It does not modify files automatically because module boundaries require architectural judgment about domain ownership, team structure, and dependency direction.

Based on the audit findings, print a numbered migration guide:

```
── Module Decomposition Guide ───────────────

Recommended module structure based on your project:

  App (main target)
  └── depends on:
      ├── FeatureHome     (Sources/FeatureHome/)
      ├── FeatureProfile  (Sources/FeatureProfile/)
      └── Core            (Sources/Core/)
          ├── Networking
          ├── Storage
          └── SharedUI

Step 1: Create Package.swift at project root (see examples/modular-architecture/after/)
Step 2: Create Sources/<ModuleName>/ directories
Step 3: Move source files into the appropriate module directories
Step 4: Add import <ModuleName> statements where needed
Step 5: In Xcode, add the local package to your app target:
        File → Add Package Dependencies → Add Local → select project root

Expected incremental build improvement: touching a file in FeatureHome rebuilds
only FeatureHome and App, not FeatureProfile or Core.
─────────────────────────────────────────────
```

Tailor the module names and structure to what was found in the project. Do not invent module names — derive them from existing directory structure and file naming patterns.

## COMPOSABILITY

Run this skill before `/protocol-separation` and `/type-annotations` — module boundaries are the largest structural change and should be established first.

**Package.resolved:** After creating `Package.swift`, run `swift package resolve` and commit the resulting `Package.resolved` file. CI/CD caches (see `/ci-cache`) use it as a cache key — an uncommitted `Package.resolved` breaks cache stability.

**Relationship to `/build-settings`:** Build settings optimise compile flags within each module. Modularisation reduces the number of files that need to be recompiled. Both improvements are additive and complement each other.

## EXAMPLES

See `examples/modular-architecture/` for:
- `before/Package.swift` — monolithic single-target structure
- `after/Package.swift` — multi-module structure
- `after/Sources/Core/UserService.swift` — shared infrastructure in the Core module
- `after/Sources/FeatureHome/HomeViewModel.swift` — feature module importing Core

## REFERENCES

- [WWDC 2022 — Meet Swift Package plugins](https://developer.apple.com/videos/play/wwdc2022/110359/) — SPM plugin system and local package integration
- [WWDC 2023 — Demystify explicitly built modules](https://developer.apple.com/videos/play/wwdc2023/10171/) — how the Swift compiler caches individual modules
- [Swift Package Manager documentation](https://www.swift.org/documentation/package-manager/) — authoritative reference for `Package.swift` manifest
- [Scaling iOS builds with modules — Spotify Engineering](https://engineering.atspotify.com/2020/09/managing-a-large-ios-codebase/) — real-world modularisation case study
