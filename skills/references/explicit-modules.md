# explicit-modules

Audits and enables Xcode 16's explicitly built modules system, which eliminates redundant per-target module compilation to reduce clean and incremental build times.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 16: display 🟡 warning. Print the following guidance and stop:
```
⚠️  Explicitly built modules require Xcode 16+.
    You are running Xcode <version>.

    Partial equivalent (Xcode 15): Set SWIFT_ENABLE_EXPLICIT_MODULES = YES
    in your build settings to enable explicit module builds for Swift files only.
    Full Clang/ObjC module support requires Xcode 16.
```

Detect project structure:
- If `*.xcodeproj` exists: primary target is `.xcodeproj/project.pbxproj`
- If only `Package.swift` exists: note that `ENABLE_EXPLICIT_MODULE_BUILDS` does not apply to pure SPM packages — Xcode manages this automatically when the package is integrated into an Xcode project. Stop.
- If both exist (mixed): audit the `.xcodeproj`

## AUDIT

Scan `project.pbxproj` (or `.xcconfig` files if used).

**Check 1 — Global activation:**

```bash
grep "ENABLE_EXPLICIT_MODULE_BUILDS" project.pbxproj | grep -v "= YES"
```

If the setting is absent project-wide, or set to `NO` anywhere at project level: 🔴 Critical.
Note: Xcode 16 enables this by default for new projects, but existing projects migrated from earlier Xcode versions may not have it set.

**Check 2 — Per-target opt-out:**

```bash
grep -n "ENABLE_EXPLICIT_MODULE_BUILDS = NO" project.pbxproj
```

Report each target with `= NO` by name. Severity: 🟠 High per target.
Common cause: a third-party SDK vendor requires opting out. Note the target name — the user should verify whether the SDK vendor has released a compatible update.

**Check 3 — Deployment target inconsistency:**

```bash
grep "IPHONEOS_DEPLOYMENT_TARGET" project.pbxproj | sort -u
```

If more than one distinct value appears: 🟠 High. Mismatched deployment targets cause module fingerprint errors ("module compiled with different -target") when the module cache is shared across targets.

**Check 4 — Build log errors (best-effort):**

```bash
find ~/Library/Developer/Xcode/DerivedData -name "*.xcactivitylog" 2>/dev/null \
  | head -1 \
  | xargs grep -E "module mismatch|compiled with" 2>/dev/null \
  | head -5
```

If errors found: 🔴 Critical. Print each matching line as evidence.
If no log files found: skip silently.

## REPORT

Follow `../core/report-formatter.md` format.

```
🔴 [Critical] ENABLE_EXPLICIT_MODULE_BUILDS not set
Impact:         Project uses implicit module compilation. Each target recompiles
                Foundation, UIKit, and all shared framework modules independently.
                On a 5-target project this multiplies module compilation work by ~5×.
Recommendation: Enable ENABLE_EXPLICIT_MODULE_BUILDS = YES project-wide.
                The first clean build after enabling will be slower (cache population).
                All subsequent builds — including CI — will be faster.
Example:        examples/explicit-modules/

🟠 [High] ENABLE_EXPLICIT_MODULE_BUILDS = NO on target "NetworkLayer"
Impact:         This target does not benefit from the explicit module cache and
                recompiles shared modules independently on every build.
Recommendation: Enable for this target. If a third-party SDK in this target is
                incompatible, contact the SDK vendor for an updated version.

🟠 [High] Deployment target mismatch across targets
Impact:         Module fingerprints encode the deployment target. Mismatched values
                cause "module compiled with different -target" errors at build time.
Recommendation: Align IPHONEOS_DEPLOYMENT_TARGET across all targets.
                Set a single value in project-level build settings and remove
                per-target overrides.
```

## ACTION

Mode: `apply with confirmation`

1. Print the full report.
2. If no findings: print `✅ Explicit modules are already enabled for all targets. No changes needed.` and stop.
3. List proposed changes:
   ```
   Proposed changes:
   - Add ENABLE_EXPLICIT_MODULE_BUILDS = YES to project-wide Debug configuration
   - Add ENABLE_EXPLICIT_MODULE_BUILDS = YES to project-wide Release configuration
   - Remove ENABLE_EXPLICIT_MODULE_BUILDS = NO from targets: NetworkLayer, DataLayer
   ```
4. Print: `Apply these changes to project.pbxproj? [y/N]`
5. If yes:
   a. Follow `../core/git-backup.md` before modifying `project.pbxproj`.
   b. Add `ENABLE_EXPLICIT_MODULE_BUILDS = YES;` to project-wide Debug and Release build configuration blocks.
   c. Remove `ENABLE_EXPLICIT_MODULE_BUILDS = NO;` lines from opted-out targets.
   d. Print: `✅ Explicit modules enabled. First clean build will be slower (cache population). Subsequent builds will be faster.`
   e. If deployment target inconsistencies were found:
      `⚠️  Deployment target mismatch detected — align IPHONEOS_DEPLOYMENT_TARGET across all targets to prevent module fingerprint errors.`
6. If no: print `No changes made.`

**Header ordering issues (Check 4 findings):** Print guidance only — these require developer judgment:
```
⚠️  Module mismatch errors detected in build log.
    Explicit modules surface header include-order issues that implicit modules
    silently tolerated.

    Fix: in the header that produces the error, add an explicit
    #include or @import for the module it depends on.
```

## COMPOSABILITY

Run after `build-settings` — `build-settings` covers `SWIFT_ENABLE_EXPLICIT_MODULES` (Xcode 15, Swift-only). This skill extends coverage to the Xcode 16 full explicit module system (Swift + Clang).

Run before `xcode-cache` — explicit modules improves module cache reuse. Enable it before configuring the cache layer to get accurate baseline measurements.

## EXAMPLES

See `examples/explicit-modules/` for before/after.

## REFERENCES

- [WWDC24-10171 — Demystify explicitly built modules](https://developer.apple.com/videos/play/wwdc2024/10171/) — primary source for this skill
- [WWDC24-10135 — What's New in Xcode 16](https://developer.apple.com/videos/play/wwdc2024/10135/) — context and adoption overview
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference) — `ENABLE_EXPLICIT_MODULE_BUILDS` key documentation
- wwdc-skills: `references/2024/WWDC24-10171-demystify-explicitly-built-modules.md`
