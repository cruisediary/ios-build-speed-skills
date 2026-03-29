# detect-environment (core utility)

> Internal utility. Not user-invocable. Referenced by all category skills in their ENVIRONMENT section.

When a category skill instructs you to "follow skills/core/detect-environment.md", execute these steps:

## Detection Steps

1. Run `xcodebuild -version` and extract the Xcode version number.
   Example output: `Xcode 16.2` → version `16.2`

2. Run `swift --version` and extract the Swift version number.
   Example output: `swift-driver version: 1.115.1 Apple Swift version 5.10` → version `5.10`

3. Check for package managers by looking for these files in the current directory:
   - `Package.swift` → SPM
   - `Podfile` → CocoaPods
   - `Cartfile` → Carthage
   If more than one is present, report as "Mixed (SPM + CocoaPods)" etc.

4. Display the environment summary before any findings:

```
── Environment ──────────────────────────────
Xcode:           16.2
Swift:           5.10
Package Manager: SPM
─────────────────────────────────────────────
```

## Version Gates

| Xcode | Swift | Status |
|---|---|---|
| 16+ | 6+ | ✅ Full support — all features, Swift 6 concurrency annotations |
| 15.x | 5.9–5.10 | ✅ Full support |
| 14.x | 5.7–5.8 | ⚠️ Core features; some cache paths differ from Xcode 15+ |
| < 14 | < 5.7 | 🔴 Unsupported |

**If Xcode < 14 is detected**, immediately print:

```
🔴 Unsupported Xcode version: X.X (minimum supported: 14.0)
Automated changes are disabled. Recommendations below are printed as guidance only.
```

Then continue with AUDIT and REPORT as normal — skip only the ACTION (apply) steps.

## REFERENCES

- [xcodebuild man page — Apple Developer](https://developer.apple.com/library/archive/technotes/tn2339/_index.html) — `xcodebuild -version` output format
- [Swift version compatibility — Swift.org](https://www.swift.org/blog/swift-5-9-released/) — Swift/Xcode version correspondence table
