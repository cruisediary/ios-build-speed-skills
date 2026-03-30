# build-settings

Audits and applies Xcode build settings flags to reduce compile and link times.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

Detect project structure:
- If `*.xcodeproj` exists: primary target is `.xcodeproj/project.pbxproj`
- If only `Package.swift` exists: note that most build settings do not apply to pure SPM packages (they are controlled by `swift build` flags)
- If both exist (mixed): audit both

## AUDIT

Scan `project.pbxproj` (or `.xcconfig` files if used) for the following settings per build configuration.

**For Debug configuration:**

| Setting | Expected value | Issue if different | Severity |
|---|---|---|---|
| `SWIFT_COMPILATION_MODE` | `incremental` | `wholemodule` rebuilds all Swift files on every change | 🔴 Critical |
| `ONLY_ACTIVE_ARCH` | `YES` | Builds all architectures, doubles time on Apple Silicon Macs | 🟠 High |
| `SWIFT_OPTIMIZATION_LEVEL` | `-Onone` | Any optimization level slows debug compilation | 🟠 High |
| `DEBUG_INFORMATION_FORMAT` | `dwarf` | `dwarf-with-dsym` generates a dSYM bundle, slowing each build | 🟠 High |
| `ENABLE_TESTABILITY` | `YES` on app/framework targets (Debug only) | Setting it on all targets or in Release adds unnecessary overhead | 🟡 Medium |
| `GCC_OPTIMIZATION_LEVEL` | `0` | Any optimization level > 0 slows Obj-C compilation | 🟠 High (mixed projects only) |

**For all configurations (all targets):**

| Setting | Expected value | Issue if different | Severity |
|---|---|---|---|
| `SWIFT_ENABLE_EXPLICIT_MODULES` | `YES` (Xcode 15+) | Implicit module rebuilds cause redundant work across files | 🟠 High |
| `EAGER_LINKING` | `YES` (Xcode 14+) | Linking waits for all compilation to finish instead of starting as soon as possible | 🟡 Medium |
| `ENABLE_USER_SCRIPT_SANDBOXING` | `YES` (Xcode 14+) | Script phases without sandboxing run on every build, blocking parallelism | 🟡 Medium |
| `BUILD_LIBRARY_FOR_DISTRIBUTION` | `NO` on internal modules | Forces whole-module optimisation even in Debug, negating incremental builds | 🟠 High |

**For Debug configuration — post-processing:**

| Setting | Expected (Debug) | Issue if different | Severity |
|---|---|---|---|
| `DEPLOYMENT_POSTPROCESSING` | `NO` | Master switch: triggers stripping, validation, and symbol copying — all wasted work in Debug | 🟠 High |
| `DEAD_CODE_STRIPPING` | `NO` | Extra linker pass to remove unreachable code; no benefit in Debug, adds link time | 🟠 High |
| `STRIP_INSTALLED_PRODUCT` | `NO` | Running `strip` on the binary in Debug breaks debugger stepping and breakpoints | 🟠 High |
| `STRIP_SWIFT_SYMBOLS` | `NO` | Post-link Swift symbol stripping step; unneeded in Debug | 🟡 Medium |
| `VALIDATE_PRODUCT` | `NO` | End-of-build validation (architecture checks, entitlements); unnecessary during development | 🟡 Medium |

**For Debug configuration — resources:**

| Setting | Expected (Debug) | Issue if different | Severity |
|---|---|---|---|
| `COMPRESS_PNG_FILES` | `NO` | Runs pngcrush on every PNG resource; asset-heavy projects add seconds per build | 🟡 Medium |
| `ASSETCATALOG_COMPILER_OPTIMIZATION` | `time` | `space` runs extra compression passes on the asset catalog; use `time` in Debug | 🟡 Medium |

**For Debug configuration — sanitizers (must not be left on permanently):**

| Setting | Expected | Issue if enabled in default Debug | Severity |
|---|---|---|---|
| `ENABLE_ADDRESS_SANITIZER` | `NO` | Instruments every memory access; adds 20–40% build time and doubles binary size | 🔴 Critical |
| `ENABLE_THREAD_SANITIZER` | `NO` | Instruments all memory accesses for data race detection; similar overhead to ASan | 🔴 Critical |
| `ENABLE_UNDEFINED_BEHAVIOR_SANITIZER` | `NO` | Instruments arithmetic operations and type casts; measurable build overhead | 🟠 High |

**For Release configuration, verify (report but do not auto-change):**
- `SWIFT_OPTIMIZATION_LEVEL` should be `-O` (not `-Onone`)
- `DEBUG_INFORMATION_FORMAT` should be `dwarf-with-dsym` (needed for crash symbolication)
- `DEPLOYMENT_POSTPROCESSING` should be `YES`

## REPORT

Follow `../core/report-formatter.md` format.

For each misconfigured setting, include the current value and the expected value:
```
🔴 [Critical] SWIFT_COMPILATION_MODE = wholemodule (Debug)
Impact:         Whole-module compilation recompiles all Swift files on every change, making incremental builds impossible
Recommendation: Set SWIFT_COMPILATION_MODE = incremental for Debug configuration
Example:        examples/build-settings/
```

## ACTION

Mode: `apply with confirmation`

1. Print the full report.
2. If no findings, stop.
3. List proposed changes as a diff preview:
   ```
   Proposed changes to Debug configuration:
   - SWIFT_COMPILATION_MODE = wholemodule  →  SWIFT_COMPILATION_MODE = incremental
   - ONLY_ACTIVE_ARCH = NO                →  ONLY_ACTIVE_ARCH = YES
   ```
4. Print: `Apply these changes to project.pbxproj? [y/N]`
5. If yes:
   a. Follow `../core/git-backup.md` before modifying `project.pbxproj`.
   b. Apply changes to `project.pbxproj` using sed or direct file editing.
   c. Print: `✅ Build settings updated. Clean build folder (Cmd+Shift+K) for changes to take effect.`
6. If no: print `No changes made.`

**Note on `.xcconfig` files:** If the project uses `.xcconfig` files, modify those instead of `project.pbxproj`. Apply the same confirmation flow.

## COMPOSABILITY

Build settings optimise compile flags within targets. They are complementary to `/modular-architecture` (which reduces how many targets are recompiled) — both improvements are additive.

**Note on `CLANG_ENABLE_MODULES`:** This flag is audited by `/xcode-cache` (ccache integration requires it). Do not modify it here.

## EXAMPLES

See `examples/build-settings/` for before/after xcconfig files.

## REFERENCES

- [WWDC 2022 — Xcode build improvements](https://developer.apple.com/videos/play/wwdc2022/110427/) — `EAGER_LINKING`, `ENABLE_USER_SCRIPT_SANDBOXING`, incremental vs whole-module
- [WWDC 2023 — Demystify explicitly built modules](https://developer.apple.com/videos/play/wwdc2023/10171/) — `SWIFT_ENABLE_EXPLICIT_MODULES` and `BUILD_LIBRARY_FOR_DISTRIBUTION` tradeoffs
- [Xcode Build Settings Reference — Apple Developer](https://developer.apple.com/documentation/xcode/build-settings-reference) — authoritative reference for all build setting keys
- [Swift compiler compilation modes — Swift.org](https://www.swift.org/blog/whole-module-optimizations/) — `incremental` vs `wholemodule` explained
- [Xcode Release Notes — Apple Developer](https://developer.apple.com/documentation/xcode-release-notes) — per-version changes to build settings
