# link-settings

Audits linker configuration and framework embedding to reduce link times and app launch overhead.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

Detect project structure:
- Count dynamic framework targets: grep `MACH_O_TYPE = mh_dylib` in `project.pbxproj`
- Count static library targets: grep `MACH_O_TYPE = staticlib`
- Count items in "Embed Frameworks" build phases across all targets

## AUDIT

**1. Old linker override**

Check `OTHER_LDFLAGS` in `project.pbxproj` for `-ld64`. The `-ld64` flag forces the legacy linker, disabling the Xcode 14+ rewritten linker that is up to 2× faster.

```
🔴 [Critical] OTHER_LDFLAGS contains -ld64
Impact:         Forces the legacy linker; the new linker (Xcode 14+) is up to 2× faster
Recommendation: Remove -ld64 from OTHER_LDFLAGS
```

**2. Internal dynamic frameworks that could be static**

Dynamic frameworks linked into the app require codesigning, embedding, and dyld loading at launch. Internal-only frameworks (not distributed as binary SDK) should use `MACH_O_TYPE = staticlib`.

Flag any framework target with `MACH_O_TYPE = mh_dylib` that:
- Is not a CocoaPods or Carthage dependency (those are external)
- Has no external consumer (only used by targets in this project)

```
🟠 [High] FeatureHome.framework is dynamic but is only consumed within this project
Impact:         Dynamic frameworks add to link time, app bundle size, and launch time
Recommendation: Set MACH_O_TYPE = staticlib on internal-only framework targets
```

**3. Missing `EXPORTED_SYMBOLS_FILE` on app targets**

App binary targets with no exported symbols file export all public symbols by default, increasing link time as the linker processes the full symbol table.

Check app targets (`.app` bundle) for `EXPORTED_SYMBOLS_FILE`. If absent:
```
🟡 [Medium] App target has no EXPORTED_SYMBOLS_FILE
Impact:         Linker processes all symbols; restricting exports reduces link time on large projects
Recommendation: Add an empty exported_symbols.txt (exports nothing) or list only symbols needed for extensions
```

**4. Embedded framework count**

Count items in `PBXCopyFilesBuildPhase` with `dstSubfolderSpec = 10` (Frameworks). Each embedded dynamic framework adds to codesigning time during builds.

If count > 8 in Debug:
```
🟡 [Medium] N dynamic frameworks are embedded in the Debug build
Impact:         Each embedded framework requires codesigning, adding to build time
Recommendation: Consider converting internal frameworks to static libraries (see item 2)
```

**5. Unused linked frameworks**

Check `PBXFrameworksBuildPhase` for frameworks listed in "Link Binary With Libraries". For each, verify at least one source file in the target contains `import <FrameworkName>`.

```
🟠 [High] SystemConfiguration.framework is linked but never imported
Impact:         Unused linked frameworks add to link time
Recommendation: Remove SystemConfiguration.framework from Link Binary With Libraries
```

## REPORT

Follow `../core/report-formatter.md` format.

## ACTION

Mode: `apply with confirmation`

**For `-ld64` removal:**
1. Show the proposed `OTHER_LDFLAGS` change.
2. Ask: `Remove -ld64 from OTHER_LDFLAGS? [y/N]`
3. If yes: follow `../core/git-backup.md`, apply change.

**For unused linked frameworks:**
1. List each unused framework.
2. Ask: `Remove these unused linked frameworks? [y/N]`
3. If yes: follow `../core/git-backup.md`, remove entries from `PBXFrameworksBuildPhase`.

**For `MACH_O_TYPE` changes and `EXPORTED_SYMBOLS_FILE`:** print guidance only — these are architectural decisions that require careful consideration of each target's consumers.

## COMPOSABILITY

Run after `/modular-architecture`. The module decomposition step determines which targets are internal-only (candidates for static linking). Run before `/ci-cache` — reducing embedded dynamic frameworks also reduces the size of artifacts cached in CI.

## EXAMPLES

See `examples/link-settings/` for before/after xcconfig and project configuration examples.

## REFERENCES

- [WWDC 2022 — Link fast: Improve build and launch times](https://developer.apple.com/videos/play/wwdc2022/110362/) — new linker, static vs dynamic tradeoffs, exported symbols
- [WWDC 2023 — Meet mergeable libraries](https://developer.apple.com/videos/play/wwdc2023/10268/) — automatic static/dynamic switching per configuration
- [Xcode Build Settings Reference — MACH_O_TYPE](https://developer.apple.com/documentation/xcode/build-settings-reference) — `mh_dylib` vs `staticlib`
- [Dynamic Library Programming Topics — Apple Developer](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/DynamicLibraries/000-Introduction/Introduction.html) — how dyld loads frameworks at launch
