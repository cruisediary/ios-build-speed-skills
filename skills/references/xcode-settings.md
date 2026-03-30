# xcode-settings

Audits and applies Xcode IDE-level preferences that affect build performance.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

Also count the number of `.swift` and `.m` source files in the project:
```bash
find . -name "*.swift" -o -name "*.m" | grep -v ".build" | grep -v "Pods" | wc -l
```
Use this count to inform the `IDEIndexingEnabled` recommendation threshold (> 200 files).

## AUDIT

Read current Xcode preference values:
```bash
defaults read com.apple.dt.Xcode ShowBuildOperationDuration 2>/dev/null || echo "not set"
defaults read com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks 2>/dev/null || echo "not set"
defaults read com.apple.dt.Xcode IDEIndexingEnabled 2>/dev/null || echo "not set"
defaults read com.apple.dt.Xcode DerivedDataLocationStyle 2>/dev/null || echo "not set"
defaults read com.apple.dt.Xcode BuildSystemSchedulerWorkerCountOverride 2>/dev/null || echo "not set"
```

Evaluate each setting against these criteria:

| Key | Issue condition | Severity |
|---|---|---|
| `ShowBuildOperationDuration` | Not set or `0` | 🔵 Low |
| `IDEBuildOperationMaxNumberOfConcurrentCompileTasks` | Set to a value lower than the CPU core count | 🟠 High |
| `IDEIndexingEnabled` | Not set (default on) or set to `1`, and source file count > 200 | 🟡 Medium |
| `DerivedDataLocationStyle` | Set to `1` (relative to workspace) or resolves to a network/slow volume | 🟡 Medium |
| `BuildSystemSchedulerWorkerCountOverride` | Set to a value lower than CPU core count | 🟠 High |

**Note:** `DerivedDataLocationStyle` is owned by this skill. `/xcode-cache` does not audit or modify this key.

Get CPU core count: `sysctl -n hw.logicalcpu`

## REPORT

Follow `../core/report-formatter.md` format.

Print the environment summary first (output of `core/detect-environment`).

For `IDEBuildOperationMaxNumberOfConcurrentCompileTasks`:
```
🟠 [High] IDEBuildOperationMaxNumberOfConcurrentCompileTasks is set below CPU core count
Impact:         Compile tasks are artificially limited, leaving CPU cores idle
Recommendation: Remove override to let Xcode use all available cores, or set to <cpu-core-count>
Example:        examples/xcode-settings/
```

For `IDEIndexingEnabled` on large projects:
```
🟡 [Medium] Index While Building is enabled on a large project (N source files)
Impact:         Background indexing during builds increases incremental build times
Recommendation: Consider disabling IDEIndexingEnabled for projects over 200 source files
Example:        examples/xcode-settings/
```

## ACTION

Mode: `apply with confirmation`

1. Print the full report.
2. If no findings, stop here.
3. List all proposed `defaults write` / `defaults delete` commands:
   ```
   Proposed changes:
   1. defaults write com.apple.dt.Xcode ShowBuildOperationDuration -bool YES
   2. defaults delete com.apple.dt.Xcode IDEBuildOperationMaxNumberOfConcurrentCompileTasks
   ```
4. Print: `Apply these changes? [y/N]`
5. If yes:
   a. Note: Xcode preferences are stored in `~/Library/Preferences/com.apple.dt.Xcode.plist`, not in the git repo. Follow `../core/git-backup.md` only if subsequent project file changes are planned; otherwise skip the git checkpoint for this preferences-only skill.
   b. Run each proposed command.
   c. Print: `✅ Settings applied. Quit and relaunch Xcode for changes to take effect.`
6. If no: print `No changes made.`

## COMPOSABILITY

Xcode IDE preferences are separate from project-level build settings. Run `/xcode-settings` first to establish a performant Xcode environment, then run `/build-settings` to optimise per-target compile flags — both improvements are additive.

`DerivedDataLocationStyle` is owned by this skill. `/xcode-cache` reads the resolved DerivedData path to configure ccache and cache pre-warming, but does not modify this key. Run `/xcode-settings` before `/xcode-cache` to ensure the DerivedData path is correct.

## EXAMPLES

See `examples/xcode-settings/` for before/after shell commands.

## REFERENCES

- [Xcode User Defaults — Apple Developer Forums](https://developer.apple.com/forums/thread/724842) — community reference for undocumented `defaults write` keys
- [WWDC 2023 — Xcode 15 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-15-release-notes) — covers `DerivedData` location and background indexing changes
- [Xcode Release Notes — Apple Developer](https://developer.apple.com/documentation/xcode-release-notes) — search "IDEBuildOperationMaxNumberOfConcurrentCompileTasks" for per-version changes
- [BuildSystemSchedulerWorkerCountOverride — Xcode Release Notes](https://developer.apple.com/documentation/xcode-release-notes) — search for "scheduler" in Xcode 14+ release notes
