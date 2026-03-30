# xcode-cache

Audits and optimizes Xcode build artifact caching: llbuild manifest cache, .gitignore completeness, ccache integration, and Tuist/XcodeGen cache configuration.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

**Note:** `DerivedDataLocationStyle` is audited by `/xcode-settings`, not this skill. If the user has not run `/xcode-settings`, suggest doing so first.

Detect additional tooling:
- `ccache` available: run `which ccache` (exit 0 = installed)
- Tuist in use: `Project.swift` or `Tuist/` directory exists
- XcodeGen in use: `project.yml` exists

## AUDIT

**1. .gitignore completeness**

Check for presence of these entries in `.gitignore`:
- `DerivedData/`
- `.build/`
- `*.xcuserstate`
- `xcuserdata/`
- `*.ipa`

Flag each missing entry as a finding.

**2. llbuild build database**

The llbuild build database lives inside DerivedData per project:
`~/Library/Developer/Xcode/DerivedData/<ProjectName-hash>/Build/Intermediates.noindex/build.db`

Check that the DerivedData path (set via `/xcode-settings`) is on a local, fast volume:
- If DerivedData is on iCloud Drive or a network volume, cache reads/writes are slow
- Run `defaults read com.apple.dt.Xcode DerivedDataLocationStyle` to confirm the location
- Note: the llbuild database is managed automatically; no manual configuration is needed

**3. ccache integration**

If `ccache` is installed (`which ccache` exits 0):
- Check if `~/.ccache/ccache.conf` exists
- Check if `CLANG_ENABLE_MODULES = YES` is set in `project.pbxproj` (required for ccache with Clang)

If `ccache` is not installed:
- Report as 🔵 Low: ccache is available and can accelerate Obj-C compilation

**4. Xcode 16+ compilation caching**

If Xcode 16+ is detected:
- Check if `COMPILATION_CACHING_ENABLED` is set in `project.pbxproj` or `.xcconfig`
- Xcode 16 introduced incremental compilation caching that persists Swift compilation results across clean builds
- If the setting is absent or `NO`, report as 🟠 High — this is a significant cache hit improvement available for free on Xcode 16+

**5. Tuist/XcodeGen cache**

If `Project.swift` (Tuist) is detected:
- Check if `tuist cache warm` is in any CI script or Makefile

If `project.yml` (XcodeGen) is detected:
- No automatic cache configuration available; note this as 🔵 Low guidance

## REPORT

Follow `../core/report-formatter.md` format.

```
🟠 [High] .gitignore missing DerivedData/ entry
Impact:         DerivedData tracked in git pollutes history and causes unnecessary network transfers
Recommendation: Add DerivedData/ to .gitignore
Example:        examples/xcode-cache/

🔵 [Low] ccache is installed but not configured for this project
Impact:         Obj-C and C files are not cached across clean builds
Recommendation: Create ~/.ccache/ccache.conf with recommended settings
Example:        examples/xcode-cache/
```

## ACTION

Mode: `apply with confirmation`

**For .gitignore findings:**

1. Show proposed additions to `.gitignore`.
2. Ask: `Add missing .gitignore entries? [y/N]`
3. If yes:
   a. Follow `../core/git-backup.md`.
   b. Append missing entries to `.gitignore`.
   c. Print: `✅ .gitignore updated.`

**For ccache configuration:**

1. Show proposed `~/.ccache/ccache.conf` content.
2. Ask: `Create ccache configuration? [y/N]`
3. If yes:
   a. Create `~/.ccache/ccache.conf` with contents from `examples/xcode-cache/after.ccache.conf`.
   b. Print: `✅ ccache.conf created. Run a clean build to populate the cache.`
   c. Note: `~/.ccache/` is outside the git repo — no git backup needed.

## COMPOSABILITY

`.gitignore` and CI caching are complementary, not mutually exclusive. Adding `.build/` to `.gitignore` prevents build artifacts from being accidentally committed. The `/ci-cache` skill separately caches `.build/` between CI runs — both are needed and reinforce each other.

**DerivedData location:** The DerivedData cache path used by `/ci-cache` depends on `DerivedDataLocationStyle`. Run `/xcode-settings` to confirm the location before configuring CI caching.

## EXAMPLES

See `examples/xcode-cache/` for before/after .gitignore and ccache.conf.

## REFERENCES

- [ccache documentation](https://ccache.dev/documentation.html) — configuration reference for `ccache.conf`
- [llbuild — apple/swift-llbuild](https://github.com/apple/swift-llbuild) — Swift's low-level build system source code
- [WWDC 2022 — Link fast: Improve build and launch times](https://developer.apple.com/videos/play/wwdc2022/110362/) — DerivedData internals and cache invalidation
- [Xcode Release Notes — Apple Developer](https://developer.apple.com/documentation/xcode-release-notes) — per-version DerivedData and build system changes
