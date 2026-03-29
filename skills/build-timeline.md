# build-timeline

Identifies the slowest-compiling files and functions in your Xcode project.

## TRIGGER

Invocation: `/build-timeline`
Description: Identify the slowest-compiling files and functions in your Xcode project.

## ENVIRONMENT

Follow `skills/core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

## AUDIT

Two complementary mechanisms:

**1. File-level timing** via `xcodebuild -showBuildTimingSummary`
No project changes needed. Prints per-phase compile totals at the end of a build:
```bash
xcodebuild -showBuildTimingSummary -scheme <YourScheme> -destination 'generic/platform=iOS Simulator'
```

**2. Function-level timing** via compiler frontend flags:
```
OTHER_SWIFT_FLAGS = -Xfrontend -debug-time-function-bodies -Xfrontend -debug-time-expression-type-checking
```
- `-debug-time-function-bodies` — emits per-function compile times to the build log
- `-debug-time-expression-type-checking` — emits per-expression type-checking times

These flags must be added temporarily and removed after diagnosis.

**Log detection:**
```bash
ls -t ~/Library/Developer/Xcode/DerivedData/*/Logs/Build/*.xcactivitylog 2>/dev/null | head -1
```
`.xcactivitylog` files are gzip-compressed SLF0 structured logs. The most practical way to read timing results is:
1. **Xcode Build Report** (recommended): open the Report Navigator (Cmd+9), select the latest build, click on a compile phase to see per-file times
2. **xclogparser** (programmatic): `brew install xclogparser && xclogparser parse --file <path>.xcactivitylog --reporter flatJson | jq '[.[] | select(.detailStepType=="swiftCompilation") | {file: .title, duration: .duration}] | sort_by(.duration) | reverse | .[:10][]'`

**Audit steps:**
1. Check if `OTHER_SWIFT_FLAGS` already contains `-debug-time-function-bodies`
2. Check for a `.xcactivitylog` modified within the last 24 hours
3. If log found: surface Top 10 slowest files and Top 10 slowest functions
4. If no log found: enter guided mode (see ACTION)

## REPORT

Follow `skills/core/report-formatter.md` format.

**If timing data available:**
```
🟠 [High] AppViewModel.swift — 14.3s compile time
Impact:         Every incremental build touching this file waits 14.3s
Recommendation: Inspect for complex type inference, large switch statements, or long string interpolation chains
Example:        examples/build-timeline/
```

**If no recent log found:**
```
🔵 [Info] No recent build log found
Impact:         Cannot determine which files are slowest without timing data
Recommendation: Run a build with timing flags enabled (see ACTION)
```

## ACTION

Mode: `guided`

**Path A — Log exists:**
1. Print Top 10 slowest files and Top 10 slowest functions from the most recent log.
2. For each file above 5s, suggest which skill is most likely to help:
   - Many protocols → `/protocol-separation`
   - Untyped closures or complex expressions → `/type-annotations`
   - Many files uniformly slow → `/build-settings`
   - Swift Concurrency-heavy files → `/concurrency-settings`
3. Print: `Run /build-timeline again after applying recommended skills to measure improvement.`

**Path B — No log, offer timing flags:**
1. Print:
   ```
   To enable function-level timing, add these flags to your Debug configuration:
   OTHER_SWIFT_FLAGS = -Xfrontend -debug-time-function-bodies -Xfrontend -debug-time-expression-type-checking
   ```
2. Follow `skills/core/git-backup.md` before modifying `project.pbxproj`.
3. Print a diff preview:
   ```
   Proposed changes to Debug configuration:
   + OTHER_SWIFT_FLAGS = -Xfrontend -debug-time-function-bodies -Xfrontend -debug-time-expression-type-checking
   ```
4. Print: `Apply these changes to project.pbxproj? [y/N]`
5. If yes: apply to Debug configuration only in `project.pbxproj`.
6. Print: `Run a full build (Cmd+B), then invoke /build-timeline again to see results.`
7. Print: `⚠️ Remove these flags after diagnosis — they add overhead to every build.`

**Cleanup:**
If `-debug-time-function-bodies` is already set when the skill runs, print:
```
⚠️ Timing flags are currently enabled. Remove them after diagnosis:
Apply removal? [y/N]
```
If yes: follow `skills/core/git-backup.md` and remove the flags from `project.pbxproj`.

## COMPOSABILITY

Run `/build-timeline` first (before any other skill) to establish a baseline, then again after each skill to measure improvement.

Use findings to prioritize which skills to apply next:
- Slowest files have many protocol conformances → `/protocol-separation`
- Slowest files have untyped closures or complex generics → `/type-annotations`
- Many files uniformly slow → `/build-settings` (`SWIFT_COMPILATION_MODE`)
- Swift Concurrency-heavy files dominate → `/concurrency-settings`

## EXAMPLES

See `examples/build-timeline/` for sample timing output before and after optimization.

## REFERENCES

- [WWDC 2022 — Xcode build improvements (session 110427)](https://developer.apple.com/videos/play/wwdc2022/110427/) — `-showBuildTimingSummary` and incremental build diagnostics
- [Swift compiler performance — Swift.org](https://github.com/apple/swift/blob/main/docs/CompilerPerformance.md) — `-debug-time-function-bodies` and `-debug-time-expression-type-checking`
- [Xcode Build Settings Reference — Apple Developer](https://developer.apple.com/documentation/xcode/build-settings-reference) — `OTHER_SWIFT_FLAGS`
