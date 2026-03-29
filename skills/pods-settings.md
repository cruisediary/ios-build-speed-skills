# pods-settings

Audits CocoaPods configuration for linkage settings that slow builds and app launch.

## TRIGGER

Invocation: `/pods-settings`
Description: Audit CocoaPods linkage settings to reduce build time and app launch overhead.

## ENVIRONMENT

Follow `skills/core/detect-environment.md`.

If no `Podfile` found in the project root: print `No Podfile found — this skill applies to CocoaPods projects only.` and exit.

If `Podfile` found but no `Pods/` directory: run Podfile-only checks, skip Pods-directory checks, and print `⚠️ Run pod install to enable full audit.`

## AUDIT

**Podfile checks:**

| Finding | Severity |
|---|---|
| `use_frameworks!` without `:linkage => :static` (defaults to `:dynamic`) | 🔴 Critical |
| Missing `inhibit_all_warnings!` | 🔵 Low |

Detect with:
```bash
grep "use_frameworks!" Podfile
grep "inhibit_all_warnings" Podfile
```

**Pods/ directory checks (if `pod install` has been run):**

Count dynamic framework bundles:
```bash
find Pods -name "*.framework" -maxdepth 4 2>/dev/null | wc -l
```
Report count as informational before applying the fix — static `.framework` bundles still appear on disk after switching to `:linkage => :static`, so this count does not decrease after the fix and should not be used as a post-fix metric.

Check for dynamic pod targets in `Pods/Pods.xcodeproj/project.pbxproj`:
```bash
grep "MACH_O_TYPE = mh_dylib" Pods/Pods.xcodeproj/project.pbxproj | wc -l
```
Report count as informational — each `mh_dylib` target adds a dyld load at app launch. After switching to `:linkage => :static` this count should drop to 0; any remaining entries indicate pods that could not be linked statically.

## REPORT

Follow `skills/core/report-formatter.md` format.

```
🔴 [Critical] use_frameworks! without :linkage => :static (Podfile)
Impact:         All pod targets compile as dynamic frameworks — each adds a dyld load at app launch and an embed + codesign step per build
Recommendation: Change to: use_frameworks! :linkage => :static
                Run: pod install
Example:        examples/pods-settings/
```

## ACTION

Mode: `guided`

1. Print the full report.
2. If no findings, stop.
3. For `use_frameworks!` finding, print:

```
Step 1 — Update Podfile:
  Change:  use_frameworks!
  To:      use_frameworks! :linkage => :static

Step 2 — Reinstall pods:
  pod install

Step 3 — Build and resolve errors (Cmd+B):
  Common fixes:
  - Pod fails to build as static: check the pod's GitHub issues for static linkage support, or override via post_install hook:
      post_install do |installer|
        installer.pods_project.target('PodName').build_configurations.each do |c|
          c.build_settings['MACH_O_TYPE'] = 'mh_dylib'
        end
      end
  - @objc symbols missing: add use_modular_headers! or per-pod :modular_headers => true

Step 4 — Verify improvement:
  Instruments → App Launch template → compare dylib load count before/after
```

4. For missing `inhibit_all_warnings!`: print the line to add as the first line inside the target block (scoped suppression). Note that this reduces build log noise but does not affect compile time.

## COMPOSABILITY

Run `/pods-settings` before `/link-settings` — resolving CocoaPods dynamic frameworks first gives `/link-settings` an accurate picture of remaining dynamic frameworks in the app's own targets.

For Swift Package Manager-only projects: skip this skill. Use `/xcode-cache` and `/ci-cache` for dependency-related speed improvements.

## EXAMPLES

See `examples/pods-settings/` for before/after Podfile.

## REFERENCES

- [WWDC 2022 — Link fast: Improve build and launch times (session 110362)](https://developer.apple.com/videos/play/wwdc2022/110362/) — static vs dynamic frameworks and dyld load time
- [CocoaPods — use_frameworks!](https://guides.cocoapods.org/syntax/podfile.html#use_frameworks_bang) — `:linkage => :static` option
- [CocoaPods — use_modular_headers!](https://guides.cocoapods.org/syntax/podfile.html#use_modular_headers_bang) — required for some pods with static linkage
