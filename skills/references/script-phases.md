# script-phases

Audits Xcode Run Script build phases for missing input/output declarations and sandboxing settings that cause unnecessary re-execution and block build parallelism.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

This skill requires a `.xcodeproj` — pure SPM packages do not have Run Script phases. If only `Package.swift` is found, print:
```
No .xcodeproj found. Run Script phases are an Xcode project concept — no action needed for pure SPM packages.
```

## AUDIT

Parse `project.pbxproj` for all `PBXShellScriptBuildPhase` sections.

For each script phase, check:

**1. Missing input/output file declarations**

A Run Script phase without declared inputs AND outputs runs on every build, even when nothing has changed. Xcode cannot determine whether the outputs are up-to-date.

Flag if both `inputPaths`/`inputFileListPaths` AND `outputPaths`/`outputFileListPaths` are empty arrays.

```
🔴 [Critical] "Generate Assets" has no input/output file declarations
Impact:         Script runs on every build regardless of changes, adding N seconds to every incremental build
Recommendation: Declare input files (source files the script reads) and output files (files it produces)
```

**2. `alwaysOutOfDate` flag**

If `alwaysOutOfDate = 1` is set, Xcode forces re-execution every build.

```
🔴 [Critical] "Swiftgen" has alwaysOutOfDate = 1
Impact:         Script is forced to re-run on every build
Recommendation: Remove alwaysOutOfDate flag and declare proper input/output file lists
```

**3. Missing `ENABLE_USER_SCRIPT_SANDBOXING`**

Script phases on unsandboxed targets can read and write arbitrary paths, preventing Xcode from running them in parallel with compilation. (Audited in `/build-settings`; referenced here for completeness.)

Flag as 🟡 Medium if `ENABLE_USER_SCRIPT_SANDBOXING = NO` or absent.

**4. Script phase position relative to compilation**

In `project.pbxproj`, `PBXShellScriptBuildPhase` entries that appear before `PBXSourcesBuildPhase` in the target's build phase list block compilation from starting until the script finishes.

Flag any script phase that runs before the Sources phase unless it generates source files that compilation requires.

## REPORT

Follow `../core/report-formatter.md` format.

```
🔴 [Critical] "Run SwiftGen" has no input/output file declarations
Impact:         Script runs on every incremental build, adding ~8 seconds regardless of changes
Recommendation: Add inputFileListPaths pointing to source assets; add outputFileListPaths pointing to generated files
Example:        examples/script-phases/

🟡 [Medium] "Lint" runs before Sources phase in AppTarget
Impact:         Compilation cannot start until the lint script finishes
Recommendation: Move script phase to after Sources phase if it does not generate files needed for compilation
Example:        examples/script-phases/
```

## ACTION

Mode: `apply with confirmation`

**For missing input/output declarations:** Print guidance only — the correct input and output paths depend on what the script does. Do not auto-generate file lists.

**For `alwaysOutOfDate = 1`:** Propose removal with confirmation.

1. Print: `Remove alwaysOutOfDate from "<script-name>"? [y/N]`
2. If yes:
   a. Follow `../core/git-backup.md` before modifying `project.pbxproj`.
   b. Remove `alwaysOutOfDate = 1` from the phase.
   c. Print: `✅ Removed. Declare input/output file lists to prevent the script from running every build.`

**For phase ordering:** Print guidance only — reordering phases requires understanding what each script produces.

## COMPOSABILITY

Run this skill after `/build-settings` (which audits `ENABLE_USER_SCRIPT_SANDBOXING`). The two skills are complementary: sandboxing allows Xcode to parallelize scripts; input/output declarations allow Xcode to skip them when outputs are up-to-date.

## EXAMPLES

See `examples/script-phases/` for before/after build phase configurations.

## REFERENCES

- [WWDC 2022 — Demystify parallelization in Xcode builds](https://developer.apple.com/videos/play/wwdc2022/110364/) — input/output file lists, sandboxing, and build phase ordering
- [WWDC 2018 — Behind the Scenes of the Xcode Build Process](https://developer.apple.com/videos/play/wwdc2018/415/) — Run Script phase lifecycle and when phases re-execute
- [Xcode Build Settings Reference — ENABLE_USER_SCRIPT_SANDBOXING](https://developer.apple.com/documentation/xcode/build-settings-reference) — sandboxing flag documentation
- [Input and output files for Run Script phases — Apple Developer](https://developer.apple.com/documentation/xcode/running-custom-scripts-during-a-build) — how to declare file dependencies
