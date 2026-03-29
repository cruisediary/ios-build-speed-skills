# report-formatter (core utility)

> Internal utility. Not user-invocable. Category skills include this format definition in their REPORT section.

This file defines the standard output format for all ios-build-speed skill reports.

## Severity Levels

| Icon | Level | When to use |
|---|---|---|
| 🔴 | Critical | Setting actively harms build speed or correctness; fix immediately |
| 🟠 | High | Clear improvement available; low risk to apply |
| 🟡 | Medium | Improvement available but requires project-specific judgment |
| 🔵 | Low | Minor optimization; apply if convenient |

## Report Structure

### Header (always first)

```
── Findings: <skill-name> ───────────────────
```

### Per-finding format

```
🟠 [High] <Finding title>
Impact:         <One-line description of the build speed effect>
Recommendation: <One-line description of the change to make>
Example:        examples/<skill-name>/ (omit this line if no example applies)
```

### Footer (always last in REPORT section)

```
Total: X finding(s)   🔴 N  🟠 N  🟡 N  🔵 N
─────────────────────────────────────────────
```

### No findings

If the audit finds no issues:

```
── Findings: <skill-name> ───────────────────
✅ No issues found. Build settings are already optimized.
─────────────────────────────────────────────
```

## Example Full Report

```
── Environment ──────────────────────────────
Xcode:           16.2
Swift:           5.10
Package Manager: SPM
─────────────────────────────────────────────

── Findings: build-settings ─────────────────

🔴 [Critical] SWIFT_COMPILATION_MODE is set to wholemodule in Debug
Impact:         Whole-module compilation rebuilds all Swift files on every change
Recommendation: Set SWIFT_COMPILATION_MODE = incremental for Debug configuration
Example:        examples/build-settings/

🟠 [High] ONLY_ACTIVE_ARCH is not set for Debug
Impact:         Builds all architectures in debug, doubling compile time on Apple Silicon
Recommendation: Set ONLY_ACTIVE_ARCH = YES for Debug configuration
Example:        examples/build-settings/

Total: 2 finding(s)   🔴 1  🟠 1  🟡 0  🔵 0
─────────────────────────────────────────────
```
