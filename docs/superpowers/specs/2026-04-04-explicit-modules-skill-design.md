# Explicit Modules Skill Design

## Goal

Add `skills/references/explicit-modules.md` to `ios-build-speed-skills` and enhance `skills/references/concurrency-settings.md`, covering two build speed improvements sourced from WWDC24 and WWDC25 sessions in `wwdc-skills`. Update the SKILL.md `description` field so the skill activates for the new query patterns.

## Source Sessions (from wwdc-skills)

| Session | Year | Key content |
|---|---|---|
| WWDC24-10171 — Demystify Explicitly Built Modules | 2024 | `ENABLE_EXPLICIT_MODULE_BUILDS`, scan-then-compile model, module fingerprinting, header ordering |
| WWDC24-10135 — What's New in Xcode | 2024 | Swift 6 migration assistant, `SWIFT_STRICT_CONCURRENCY`, explicit modules overview |
| WWDC25-247 — What's New in Xcode 26 | 2025 | Redundant `@MainActor` fix-its, `nonisolated(unsafe)` cleanup, Xcode 26 annotation tooling |

## Problem

Two categories of build speed improvements are absent from `ios-build-speed-skills`:

1. **Explicitly Built Modules** — Xcode 16's `ENABLE_EXPLICIT_MODULE_BUILDS` eliminates redundant per-target module compilation. No existing skill covers it. `build-settings.md` mentions `SWIFT_ENABLE_EXPLICIT_MODULES` (Xcode 15, Swift-only) but not the broader Xcode 16 setting.

2. **Swift annotation bloat** — Redundant `@MainActor` on UIViewController subclasses and `nonisolated(unsafe)` workarounds increase incremental type-checker work. `concurrency-settings.md` counts `@MainActor` occurrences but does not distinguish redundant ones or flag `nonisolated(unsafe)`.

Additionally, the SKILL.md `description` field contains no mention of modules or annotation-related queries, so users asking about these topics never trigger the skill.

## Trigger Probability Analysis

| Query | Before | After (with description update) |
|---|---|---|
| "ENABLE_EXPLICIT_MODULE_BUILDS" | 0% | ~90% |
| "How do I enable explicit modules?" | 0% | ~85% |
| "Module recompilation is wasting build time" | ~35% | ~85% |
| "Xcode 16 module cache not working" | 0% | ~75% |
| "@MainActor is redundant on my class" | 0% | ~70% |
| "nonisolated(unsafe) slowing builds" | 0% | ~65% |

Adding a reference file alone changes nothing — the `description` field drives activation. Both changes are required.

---

## Change 1: New skill — `explicit-modules.md`

### File location
`skills/references/explicit-modules.md`

### Skill contract (7 sections)

**ENVIRONMENT**
- Require Xcode 16+. If Xcode < 16: display 🟡 warning, print guidance for `SWIFT_ENABLE_EXPLICIT_MODULES` (Xcode 15 partial equivalent), skip automated changes.
- Follow `../core/detect-environment.md`.
- Detect xcodeproj vs Package.swift vs mixed.

**AUDIT — 4 checks**

| Check | What to scan | Severity |
|---|---|---|
| 1 — Global activation | `ENABLE_EXPLICIT_MODULE_BUILDS` absent or `= NO` in project-wide settings | 🔴 Critical |
| 2 — Per-target opt-out | `ENABLE_EXPLICIT_MODULE_BUILDS = NO` on individual targets | 🟠 High per target |
| 3 — Deployment target inconsistency | Targets with differing `IPHONEOS_DEPLOYMENT_TARGET` values | 🟠 High (primary cause of module fingerprint mismatches) |
| 4 — Build log errors | `module mismatch`, `compiled with`, or targets with zero `(cached)` labels in most recent build log | 🔴 Critical if found |

Check 1 and 2 via `grep` on `project.pbxproj`.
Check 3 via `grep IPHONEOS_DEPLOYMENT_TARGET project.pbxproj | sort -u`.
Check 4 via `find ~/Library/Developer/Xcode/DerivedData -name "*.xcactivitylog" 2>/dev/null | head -1 | xargs grep -E "module mismatch|compiled with" 2>/dev/null | head -5` (best-effort, skip if no logs found).

**REPORT**
Follow `../core/report-formatter.md` format. Example:
```
🔴 [Critical] ENABLE_EXPLICIT_MODULE_BUILDS not set (project defaults to implicit modules)
Impact:         Each target recompiles Foundation, UIKit, and shared framework modules independently.
                On a 5-target project this multiplies module compilation work by ~5×.
Recommendation: Enable ENABLE_EXPLICIT_MODULE_BUILDS = YES for all targets.
Example:        examples/explicit-modules/
```

**ACTION**
Mode: `apply with confirmation`

1. Print full report.
2. If no findings, stop.
3. List proposed changes:
   ```
   Proposed changes:
   - Add ENABLE_EXPLICIT_MODULE_BUILDS = YES to project-wide Debug and Release configurations
   - Remove ENABLE_EXPLICIT_MODULE_BUILDS = NO from targets: [list]
   ```
4. Print: `Apply these changes to project.pbxproj? [y/N]`
5. If yes:
   a. Follow `../core/git-backup.md` before modifying `project.pbxproj`.
   b. Apply changes.
   c. Print: `✅ Explicit modules enabled. First clean build will be slower (cache population). Subsequent builds will be faster.`
   d. If deployment target inconsistencies were found: `⚠️ Deployment target mismatch detected across targets — align IPHONEOS_DEPLOYMENT_TARGET to prevent module fingerprint errors.`
6. If no: print `No changes made.`

Header ordering issues (Check 4 errors): print guidance only. These require developer judgment to fix the specific `#include` declarations in affected headers.

**COMPOSABILITY**
```
Run after:  build-settings (covers SWIFT_ENABLE_EXPLICIT_MODULES Xcode 15 equivalent)
Run before: xcode-cache (explicit modules improves cache hit rate — enable first)
```

Slot in recommended sequence: after Step 3 (`build-settings`), before Step 12 (`xcode-cache`).

**EXAMPLES**
See `examples/explicit-modules/` for before/after.

**REFERENCES**
- [WWDC24-10171 — Demystify explicitly built modules](https://developer.apple.com/videos/play/wwdc2024/10171/) — primary source
- [WWDC24-10135 — What's New in Xcode 16](https://developer.apple.com/videos/play/wwdc2024/10135/) — context and migration steps
- [Xcode Build Settings Reference — ENABLE_EXPLICIT_MODULE_BUILDS](https://developer.apple.com/documentation/xcode/build-settings-reference)
- wwdc-skills: `references/2024/WWDC24-10171-demystify-explicitly-built-modules.md`

---

## Change 2: Enhance `concurrency-settings.md`

### What changes

**AUDIT Secondary section — add 2 grep checks:**

```bash
# Redundant @MainActor on UIKit/AppKit base class subclasses
# -A1 captures the line after each @MainActor hit, handling the standard
# multi-line annotation style (@MainActor on its own line above `class`)
grep -rn -A1 "@MainActor" --include="*.swift" . | grep -v "\.build" \
  | grep -E "class .+: (UIViewController|NSViewController|UIView|UITableViewCell|UICollectionViewCell)" | wc -l

# nonisolated(unsafe) — indicates unresolved isolation issues
# -F treats the string as a fixed literal (parens are not regex metacharacters)
grep -rFn "nonisolated(unsafe)" --include="*.swift" . | grep -v "\.build" | wc -l
```

| Finding | Threshold | Severity | Note |
|---|---|---|---|
| Redundant `@MainActor` on UIKit/AppKit subclasses | > 0 | 🟡 Medium | UIViewController and its subclasses are implicitly `@MainActor`; annotation is redundant and adds type-checker noise |
| `nonisolated(unsafe)` usages | > 5 | 🟡 Medium | Indicates unresolved actor isolation; each instance adds incremental type-checker work |

**Add to REPORT section:**
```
🟡 [Medium] 4 redundant @MainActor annotations on UIViewController subclasses
Impact:         Redundant annotations do not change behavior but increase incremental
                type-checking work. Each annotation is an additional constraint the
                type checker must verify on every rebuild of the affected file.
Recommendation: Remove @MainActor from classes that inherit from UIViewController,
                NSViewController, UIView, UITableViewCell, UICollectionViewCell.
                Xcode 26: use "Fix All Issues" to remove in bulk.
```

**Add to REFERENCES:**
- [WWDC24-10135 — What's New in Xcode 16](https://developer.apple.com/videos/play/wwdc2024/10135/) — Swift 6 migration assistant
- [WWDC25-247 — What's New in Xcode 26](https://developer.apple.com/videos/play/wwdc2025/247/) — `@MainActor` fix-its, `nonisolated(unsafe)` cleanup

---

## Change 3: Update SKILL.md description and routing table

### Description update

**Before:**
```
"Use when the user mentions slow iOS/Xcode builds, wants to improve compile time, reduce incremental build times, optimize Xcode settings, fix slow CI pipelines, or asks about DerivedData, Swift compilation, CocoaPods linkage, build flags, or GitHub Actions for iOS."
```

**After:**
```
"Use when the user mentions slow iOS/Xcode builds, wants to improve compile time, reduce incremental build times, optimize Xcode settings, fix slow CI pipelines, or asks about DerivedData, Swift compilation, CocoaPods linkage, build flags, GitHub Actions for iOS, explicitly built modules, module recompilation, ENABLE_EXPLICIT_MODULE_BUILDS, redundant @MainActor annotations, or nonisolated(unsafe)."
```

### Routing table addition

Add one row to the `## Available skills` table:

```
| Explicitly built modules (Xcode 16+) | `references/explicit-modules.md` |
```

Position: after `Build flags, compilation mode` row (logical grouping with build settings).

---

## File Map

| Action | Path |
|---|---|
| Create | `skills/references/explicit-modules.md` |
| Modify | `skills/references/concurrency-settings.md` |
| Modify | `skills/ios-build-speed/SKILL.md` |
| Create | `examples/explicit-modules/before.md` |
| Create | `examples/explicit-modules/after.md` |

---

## Non-goals

- Covering `swift build` CLI explicit module behavior (separate implementation, separate tooling)
- Auditing module map files or `.modulemap` content (out of scope for this skill)
- Covering WWDC18-415 "Behind the Scenes of the Xcode Build Process" (not in wwdc-skills; separate initiative if needed)
- Updating trigger-tests.md test cases (separate PR)
