# Explicit Modules Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `explicit-modules.md` as a new reference skill, enhance `concurrency-settings.md` with annotation bloat detection, and update SKILL.md description + routing table so the skill triggers for module-related and annotation-related queries.

**Architecture:** Five targeted file changes: one new skill file, two new example files, one existing skill enhancement, one SKILL.md update (description + routing). Tests are structural (bash tests/run-tests.sh --static); no API calls required for verification.

**Tech Stack:** Markdown (skill files, examples), Bash (verification), YAML (no changes needed).

**Spec:** `docs/superpowers/specs/2026-04-04-explicit-modules-skill-design.md`

**Branch:** `feat/explicit-modules-skill` (already created from main)

---

## File Map

| Action | Path |
|---|---|
| Create | `skills/references/explicit-modules.md` |
| Create | `examples/explicit-modules/before.xcconfig` |
| Create | `examples/explicit-modules/after.xcconfig` |
| Modify | `skills/references/concurrency-settings.md` |
| Modify | `skills/ios-build-speed/SKILL.md` |
| Modify | `tests/run-tests.sh` |

---

## Task 1: Create `skills/references/explicit-modules.md`

**Files:**
- Create: `skills/references/explicit-modules.md`

- [ ] **Step 1: Write the skill file**

Create `skills/references/explicit-modules.md` with this exact content:

```markdown
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
```

- [ ] **Step 2: Verify file exists and has the 7 required sections**

```bash
grep -c "^## " skills/references/explicit-modules.md
```
Expected: `7`

- [ ] **Step 3: Commit**

```bash
git add skills/references/explicit-modules.md
git commit -m "feat: add explicit-modules skill (Xcode 16 ENABLE_EXPLICIT_MODULE_BUILDS)"
```

---

## Task 2: Create `examples/explicit-modules/` before and after files

**Files:**
- Create: `examples/explicit-modules/before.xcconfig`
- Create: `examples/explicit-modules/after.xcconfig`

- [ ] **Step 1: Create before.xcconfig**

Create `examples/explicit-modules/before.xcconfig` with this exact content:

```
// Before: implicit module compilation (default before Xcode 16)
// Each target compiles Foundation, UIKit, and shared modules independently.
// On a 5-target project, shared modules are compiled up to 5× redundantly.

// ENABLE_EXPLICIT_MODULE_BUILDS not set — project uses implicit modules.
// Xcode discovers and compiles modules on demand during each compiler invocation.

// Build log shows no "Scan dependencies" phase.
// Build log shows no "(cached)" labels on module compilation steps.

// Example build log (implicit):
//   Compile Swift source files for Target 'MyApp'       [5.2s]
//   Compile Swift source files for Target 'NetworkLayer' [4.8s]
//   Compile Swift source files for Target 'DataLayer'   [4.6s]
// Each target above compiles Foundation and UIKit independently.
```

- [ ] **Step 2: Create after.xcconfig**

Create `examples/explicit-modules/after.xcconfig` with this exact content:

```
// After: explicitly built modules (Xcode 16+)
// Modules are pre-compiled once and shared across all targets via cache.
// Foundation, UIKit, and shared frameworks are compiled exactly once per build.

ENABLE_EXPLICIT_MODULE_BUILDS = YES

// Build log shows a "Scan dependencies" phase before compilation:
//   Scan dependencies for Target 'MyApp'               [0.3s]
//   Build module 'Foundation'                           [1.2s]
//   Build module 'UIKit'                                [0.8s]
//   Build module 'MyFramework'                          [0.4s]
//   Compile Swift source files for Target 'MyApp'       [2.1s]
//   Compile Swift source files for Target 'NetworkLayer' [1.4s]  ← reuses cached modules
//   Compile Swift source files for Target 'DataLayer'   [1.3s]  ← reuses cached modules
//
// "(cached)" labels appear for modules already built in a previous run.
// CI runners benefit when DerivedData is restored from cache between runs.
```

- [ ] **Step 3: Commit**

```bash
git add examples/explicit-modules/
git commit -m "docs: add explicit-modules before/after examples"
```

---

## Task 3: Enhance `skills/references/concurrency-settings.md`

**Files:**
- Modify: `skills/references/concurrency-settings.md`

- [ ] **Step 1: Read the current file**

Read `skills/references/concurrency-settings.md` to confirm exact current content of the Secondary scan section and REFERENCES section before editing.

- [ ] **Step 2: Add two grep checks to the AUDIT Secondary section**

Find this block in the file:
```
| `@MainActor` annotations (all usages) | > 20 occurrences | 🟡 Medium |

Detect with:
```bash
grep -r "@unchecked Sendable" --include="*.swift" . | grep -v "\.build" | wc -l
grep -rn "@MainActor" --include="*.swift" . | grep -v "\.build" | wc -l
```
```

Replace with:
```
| `@unchecked Sendable` conformances | > 10 occurrences | 🟡 Medium |
| `@MainActor` annotations (all usages) | > 20 occurrences | 🟡 Medium |
| Redundant `@MainActor` on UIKit/AppKit subclasses | > 0 | 🟡 Medium |
| `nonisolated(unsafe)` usages | > 5 | 🟡 Medium |

Detect with:
```bash
grep -r "@unchecked Sendable" --include="*.swift" . | grep -v "\.build" | wc -l
grep -rn "@MainActor" --include="*.swift" . | grep -v "\.build" | wc -l

# Redundant @MainActor on UIKit/AppKit base class subclasses.
# -A1 captures the line after each @MainActor hit, handling the standard
# multi-line annotation style (@MainActor on its own line above `class`).
grep -rn -A1 "@MainActor" --include="*.swift" . | grep -v "\.build" \
  | grep -E "class .+: (UIViewController|NSViewController|UIView|UITableViewCell|UICollectionViewCell)" | wc -l

# nonisolated(unsafe) indicates unresolved actor isolation.
# -F treats the string as a fixed literal (parens are not regex metacharacters).
grep -rFn "nonisolated(unsafe)" --include="*.swift" . | grep -v "\.build" | wc -l
```
```

- [ ] **Step 3: Add report examples for the two new findings**

In the REPORT section, after the existing `🔴 [Critical]` example block, add:

```
🟡 [Medium] 4 redundant @MainActor annotations on UIViewController subclasses
Impact:         Redundant annotations do not change behavior but increase incremental
                type-checking work. Each is an additional constraint the type checker
                must verify on every rebuild of the affected file.
Recommendation: Remove @MainActor from classes that inherit from UIViewController,
                NSViewController, UIView, UITableViewCell, or UICollectionViewCell —
                these are already implicitly @MainActor via UIKit's concurrency annotations.
                Xcode 26+: use "Fix All Issues" in the Issue navigator to remove in bulk.

🟡 [Medium] 8 nonisolated(unsafe) usages
Impact:         Each nonisolated(unsafe) declaration suppresses actor isolation
                enforcement. This works around data-race warnings but leaves the
                type checker additional isolation constraints to verify incrementally.
Recommendation: Migrate these to proper actor isolation (move to an actor, or use
                a @Sendable closure) to reduce incremental type-checking overhead.
```

- [ ] **Step 4: Add two references to the REFERENCES section**

Append to the existing REFERENCES list:
```
- [WWDC24-10135 — What's New in Xcode 16](https://developer.apple.com/videos/play/wwdc2024/10135/) — Swift 6 migration assistant and staged concurrency adoption
- [WWDC25-247 — What's New in Xcode 26](https://developer.apple.com/videos/play/wwdc2025/247/) — `@MainActor` fix-its and `nonisolated(unsafe)` cleanup tooling
```

- [ ] **Step 5: Verify section count unchanged (still 7 sections)**

```bash
grep -c "^## " skills/references/concurrency-settings.md
```
Expected: `7`

- [ ] **Step 6: Commit**

```bash
git add skills/references/concurrency-settings.md
git commit -m "feat: add redundant @MainActor and nonisolated(unsafe) detection to concurrency-settings"
```

---

## Task 4: Update `skills/ios-build-speed/SKILL.md`

**Files:**
- Modify: `skills/ios-build-speed/SKILL.md`

- [ ] **Step 1: Update the description field**

Find:
```
description: "Use when the user mentions slow iOS/Xcode builds, wants to improve compile time, reduce incremental build times, optimize Xcode settings, fix slow CI pipelines, or asks about DerivedData, Swift compilation, CocoaPods linkage, build flags, or GitHub Actions for iOS."
```

Replace with:
```
description: "Use when the user mentions slow iOS/Xcode builds, wants to improve compile time, reduce incremental build times, optimize Xcode settings, fix slow CI pipelines, or asks about DerivedData, Swift compilation, CocoaPods linkage, build flags, GitHub Actions for iOS, explicitly built modules, module recompilation, ENABLE_EXPLICIT_MODULE_BUILDS, redundant @MainActor annotations, or nonisolated(unsafe)."
```

- [ ] **Step 2: Add routing table row**

Find this row in the `## Available skills` table:
```
| Build flags, compilation mode | `references/build-settings.md` |
```

Add a new row immediately after it:
```
| Explicitly built modules (Xcode 16+) | `references/explicit-modules.md` |
```

Result should be:
```
| Build flags, compilation mode | `references/build-settings.md` |
| Explicitly built modules (Xcode 16+) | `references/explicit-modules.md` |
| Swift Concurrency overhead | `references/concurrency-settings.md` |
```

- [ ] **Step 3: Verify routing table now has 15 rows**

```bash
grep -c "references/" skills/ios-build-speed/SKILL.md
```
Expected: `15`

- [ ] **Step 4: Commit**

```bash
git add skills/ios-build-speed/SKILL.md
git commit -m "feat: add explicit-modules to SKILL.md routing table and extend description"
```

---

## Task 5: Update `tests/run-tests.sh` EXPECTED_STEMS

**Files:**
- Modify: `tests/run-tests.sh`

The static test hardcodes 14 expected stems. Adding `explicit-modules.md` without updating this list means Check 1 does not verify the new skill. Check 3 (orphan detection) will still pass because `explicit-modules` IS in the routing table — but Check 1 should also enumerate it.

- [ ] **Step 1: Add `explicit-modules` to EXPECTED_STEMS**

Find:
```bash
  EXPECTED_STEMS=(build-timeline build-settings concurrency-settings xcode-settings \
    script-phases link-settings modular-architecture protocol-separation \
    type-annotations preview-isolation pods-settings xcode-cache ci-cache ci-workflow)
```

Replace with:
```bash
  EXPECTED_STEMS=(build-timeline build-settings explicit-modules concurrency-settings xcode-settings \
    script-phases link-settings modular-architecture protocol-separation \
    type-annotations preview-isolation pods-settings xcode-cache ci-cache ci-workflow)
```

- [ ] **Step 2: Run static tests — verify all 45 checks pass (15 × 3)**

```bash
bash tests/run-tests.sh --static
```
Expected:
```
Trigger Static Tests
====================

Check 1: Routing table completeness
  ✅ build-timeline in routing table
  ✅ build-settings in routing table
  ✅ explicit-modules in routing table
  ... (12 more)

Check 2: File existence
  ✅ build-timeline.md exists
  ✅ explicit-modules.md exists
  ... (13 more)

Check 3: Orphan detection
  ✅ explicit-modules.md listed in routing table
  ... (14 more)

Results: 45 passed, 0 failed
```
Exit code: 0.

- [ ] **Step 3: Commit**

```bash
git add tests/run-tests.sh
git commit -m "test: add explicit-modules to EXPECTED_STEMS in static test runner"
```

---

## Task 6: Final verification + push + PR

- [ ] **Step 1: Run full static test suite**

```bash
bash tests/run-tests.sh --static
```
Expected: 45/45 passed, exit 0.

- [ ] **Step 2: Verify 7 sections in new skill**

```bash
grep "^## " skills/references/explicit-modules.md
```
Expected: ENVIRONMENT, AUDIT, REPORT, ACTION, COMPOSABILITY, EXAMPLES, REFERENCES

- [ ] **Step 3: Verify concurrency-settings has 4 grep patterns**

```bash
grep -c "grep -r" skills/references/concurrency-settings.md
```
Expected: `4` (2 original + 2 new)

- [ ] **Step 4: Verify description contains new keywords**

```bash
grep "explicitly built modules" skills/ios-build-speed/SKILL.md
grep "nonisolated" skills/ios-build-speed/SKILL.md
```
Expected: both match.

- [ ] **Step 5: Push branch**

```bash
git push origin feat/explicit-modules-skill
```

- [ ] **Step 6: Open PR**

```bash
gh pr create \
  --base main \
  --head feat/explicit-modules-skill \
  --title "Add explicit-modules skill and concurrency annotation detection" \
  --label "enhancement" \
  --body "$(cat <<'EOF'
## Summary

- Adds `skills/references/explicit-modules.md` — audits and enables Xcode 16's `ENABLE_EXPLICIT_MODULE_BUILDS`, the single biggest build system improvement in recent Xcode releases
- Adds `examples/explicit-modules/before.xcconfig` and `after.xcconfig`
- Enhances `skills/references/concurrency-settings.md` with redundant `@MainActor` detection (UIKit subclasses) and `nonisolated(unsafe)` counting
- Updates `skills/ios-build-speed/SKILL.md` description to cover new query patterns; adds routing table row for `explicit-modules`
- Updates `tests/run-tests.sh` `EXPECTED_STEMS` to include `explicit-modules`

## Trigger probability improvement

| Query | Before | After |
|---|---|---|
| "ENABLE_EXPLICIT_MODULE_BUILDS" | 0% | ~90% |
| "Module recompilation is wasting time" | ~35% | ~85% |
| "@MainActor is redundant on my class" | 0% | ~70% |
| "nonisolated(unsafe) slowing builds" | 0% | ~65% |

## Test plan

- [x] `bash tests/run-tests.sh --static` — 45/45 checks pass
- [x] `explicit-modules.md` has 7 required sections
- [x] `concurrency-settings.md` has 4 grep patterns in AUDIT
- [x] SKILL.md description contains "explicitly built modules" and "nonisolated(unsafe)"
- [x] SKILL.md routing table has 15 rows
EOF
)"
```

