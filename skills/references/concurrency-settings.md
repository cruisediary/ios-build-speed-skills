# concurrency-settings

Audits Swift Concurrency build settings that add compilation overhead in Debug builds.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes — `SWIFT_STRICT_CONCURRENCY` was introduced in Xcode 14.

## AUDIT

**Primary — scan `project.pbxproj` (or `.xcconfig` files) for Debug configuration:**

| Setting | Condition to flag | Severity |
|---|---|---|
| `SWIFT_STRICT_CONCURRENCY` | `complete` in Debug when `SWIFT_VERSION < 6` or targets are mixed | 🔴 Critical |
| `-strict-concurrency=complete` in `OTHER_SWIFT_FLAGS` | Present in Debug configuration | 🔴 Critical |
| `SWIFT_STRICT_CONCURRENCY` | `minimal` — fastest; report as info, no action | 🔵 Info |
| `SWIFT_STRICT_CONCURRENCY` | `targeted` — recommended for Debug; no action needed | ✅ OK |

**Swift 6 exception:** If all targets have `SWIFT_VERSION = 6`, `complete` is correct for the migration — do not flag.

**Secondary — scan source files (report only, no auto-change):**

| Finding | Threshold | Severity |
|---|---|---|
| `@unchecked Sendable` conformances | > 10 occurrences | 🟡 Medium |
| `@MainActor` annotations (all usages) | > 20 occurrences | 🟡 Medium |
| Redundant `@MainActor` on UIKit/AppKit subclasses | > 0 | 🟡 Medium |
| `nonisolated(unsafe)` usages | > 5 | 🟡 Medium |

Detect with:
```bash
grep -r "@unchecked Sendable" --include="*.swift" . | grep -v "\.build" | wc -l
grep -rn "@MainActor" --include="*.swift" . | grep -v "\.build" | wc -l

# Redundant @MainActor on UIKit/AppKit base class subclasses
# -A1 captures the class declaration line following the annotation
grep -rn -A1 "@MainActor" --include="*.swift" . | grep -v "\.build" \
  | grep -E "class .+: (UIViewController|NSViewController|UIView|UITableViewCell|UICollectionViewCell)" | wc -l

# nonisolated(unsafe) — indicates unresolved actor isolation
grep -rFn "nonisolated(unsafe)" --include="*.swift" . | grep -v "\.build" | wc -l
```

## REPORT

Follow `../core/report-formatter.md` format.

```
🔴 [Critical] SWIFT_STRICT_CONCURRENCY = complete (Debug)
Impact:         Full data race safety checking on every incremental build; measurably slower type-checking across the whole module
Recommendation: Set SWIFT_STRICT_CONCURRENCY = targeted for Debug. Keep complete in your CI/Release scheme.
Example:        examples/concurrency-settings/
```

```
🟡 [Medium] 4 redundant @MainActor annotations on UIViewController subclasses
Impact:         Redundant annotations do not change behavior but increase incremental
                type-checking work. Each annotation is an additional constraint the
                type checker must verify on every rebuild of the affected file.
Recommendation: Remove @MainActor from classes that inherit from UIViewController,
                NSViewController, UIView, UITableViewCell, UICollectionViewCell.
                Xcode 26: use "Fix All Issues" to remove in bulk.
```

```
🟡 [Medium] 7 nonisolated(unsafe) usages
Impact:         Each instance is a suppressed actor isolation error. The Swift type checker
                still evaluates the isolation context — it just skips enforcement.
                High counts indicate unresolved isolation design that adds type-checker work.
Recommendation: Resolve the underlying actor isolation issue and remove nonisolated(unsafe).
                Xcode 26: fix-its are available in the Issue Navigator.
```

## ACTION

Mode: `apply with confirmation`

1. Print the full report.
2. If no findings, stop.
3. List proposed changes:
   ```
   Proposed changes to Debug configuration:
   - SWIFT_STRICT_CONCURRENCY = complete  →  SWIFT_STRICT_CONCURRENCY = targeted
   ```
4. Print: `Apply these changes to project.pbxproj? [y/N]`
5. If yes:
   a. Follow `../core/git-backup.md` before modifying `project.pbxproj`.
   b. Apply changes to Debug configuration only.
   c. Print: `✅ Concurrency settings updated. Clean build folder (Cmd+Shift+K) for changes to take effect.`
   d. Print: `⚠️ Verify your CI scheme still uses SWIFT_STRICT_CONCURRENCY = complete.`
6. If no: print `No changes made.`

**Note on `.xcconfig` files:** If the project uses `.xcconfig` files, modify those instead.

## COMPOSABILITY

Complementary to `/build-settings` — both modify Debug build settings in `project.pbxproj` but target different keys. Run separately; re-read the current `project.pbxproj` state before applying either to avoid stale-state conflicts.

If `/build-timeline` identified Swift Concurrency-heavy files as the slowest compiling units, run `/concurrency-settings` next.

## EXAMPLES

See `examples/concurrency-settings/` for before/after xcconfig files.

## REFERENCES

- [WWDC 2022 — Eliminate data races using Swift Concurrency (session 110350)](https://developer.apple.com/videos/play/wwdc2022/110350/) — `SWIFT_STRICT_CONCURRENCY` modes
- [SE-0302 — Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
- [SE-0306 — Actors](https://github.com/apple/swift-evolution/blob/main/proposals/0306-actors.md)
- [Xcode Build Settings Reference — Apple Developer](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Swift 6 migration guide — Swift.org](https://www.swift.org/documentation/swift-6-concurrency-migration-guide/)
- [WWDC24-10135 — What's New in Xcode 16](https://developer.apple.com/videos/play/wwdc2024/10135/) — Swift 6 migration assistant, redundant `@MainActor` annotation guidance
- [WWDC25-247 — What's New in Xcode 26](https://developer.apple.com/videos/play/wwdc2025/247/) — `@MainActor` fix-its, `nonisolated(unsafe)` cleanup tooling
