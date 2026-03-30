---
name: ios-build-speed
description: "Use when the user mentions slow iOS/Xcode builds, wants to improve compile time, reduce incremental build times, optimize Xcode settings, fix slow CI pipelines, or asks about DerivedData, Swift compilation, CocoaPods linkage, build flags, or GitHub Actions for iOS."
license: MIT
compatibility: Requires Claude Code
metadata:
  version: "1.0.0"
---

# iOS Build Speed

Audits and fixes common causes of slow iOS/Xcode build times.

Start with `references/build-timeline.md` to establish a baseline, then follow its COMPOSABILITY section for recommended next steps.

## Available skills

| Skill | File |
|---|---|
| Build log analysis | `references/build-timeline.md` |
| Build flags, compilation mode | `references/build-settings.md` |
| Swift Concurrency overhead | `references/concurrency-settings.md` |
| Xcode IDE preferences | `references/xcode-settings.md` |
| Run Script phases | `references/script-phases.md` |
| Linker configuration | `references/link-settings.md` |
| SPM module boundaries | `references/modular-architecture.md` |
| Protocol file separation | `references/protocol-separation.md` |
| Type annotation coverage | `references/type-annotations.md` |
| SwiftUI preview extraction | `references/preview-isolation.md` |
| CocoaPods linkage | `references/pods-settings.md` |
| Local build caching | `references/xcode-cache.md` |
| CI/CD caching | `references/ci-cache.md` |
| GitHub Actions workflow | `references/ci-workflow.md` |
