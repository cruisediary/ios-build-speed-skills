# preview-isolation

Moves SwiftUI preview code out of production source files to reduce incremental recompilation.

## TRIGGER

Invocation: `/preview-isolation`
Description: Extract SwiftUI preview code to dedicated files to reduce recompilation blast radius.

## ENVIRONMENT

Follow `skills/core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

Version notes:
- Xcode 14: only `PreviewProvider` pattern applies
- Xcode 15+: both `#Preview` macro and `PreviewProvider` apply

## AUDIT

Scan all `.swift` files, excluding:
- Files in `*Tests/` or `*Test/` directories
- Files already named `*Preview.swift` or `*_Previews.swift`
- Files under `Pods/` or `.build/`

Detect in each remaining file:

| Finding | Condition | Severity |
|---|---|---|
| Preview without `#if DEBUG` guard | `#Preview` or `PreviewProvider` in a non-preview file, not wrapped in `#if DEBUG` | 🟠 High |
| Preview not in dedicated file | `#Preview` or `PreviewProvider` in a non-preview file, even if wrapped in `#if DEBUG` | 🟡 Medium |

Scan:
```bash
grep -rl "#Preview\|PreviewProvider" --include="*.swift" . \
  | grep -v "Preview\.swift" \
  | grep -v "_Previews\.swift" \
  | grep -v "Tests/" \
  | grep -v "\.build/"
```

## REPORT

Follow `skills/core/report-formatter.md` format.

```
🟠 [High] ContentView.swift — PreviewProvider without #if DEBUG guard
Impact:         Preview code compiles in Release builds and increases ContentView.swift compile unit size
Recommendation: Extract to ContentViewPreview.swift and wrap in #if DEBUG / #endif
Example:        examples/preview-isolation/
```

## ACTION

Mode: `apply with confirmation`

1. Print the full report.
2. If no findings, stop.
3. List proposed extractions:
   ```
   ContentView.swift  →  extract PreviewProvider to ContentViewPreview.swift
   ProfileView.swift  →  extract #Preview block to ProfileViewPreview.swift
   ```
4. Print: `Apply these extractions? [y/N]`
5. If yes:
   a. Follow `skills/core/git-backup.md` before modifying files.
   b. For each file:
      - Create `<OriginalName>Preview.swift` with the same `import` statements as the original
      - Move the preview struct/macro into the new file, wrapped in `#if DEBUG` / `#endif`
      - Remove the preview block from the original file
   c. Print: `✅ Preview code extracted. Build to verify (Cmd+B).`
6. If no: print `No changes made.`

**Scope:** Only moves preview declarations. Does not refactor view code or change non-preview types.

## COMPOSABILITY

Run `/preview-isolation` after `/modular-architecture` — module boundaries should be stable before moving files across targets.

Complementary to `/script-phases` — both reduce unnecessary work per incremental build. Run in either order.

## EXAMPLES

See `examples/preview-isolation/` for before/after Swift files.

## REFERENCES

- [WWDC 2023 — What's new in Xcode 15](https://developer.apple.com/videos/play/wwdc2023/10023/) — introduces `#Preview` macro
- [WWDC 2021 — Discover concurrency in SwiftUI](https://developer.apple.com/videos/play/wwdc2021/10019/) — SwiftUI preview and actor isolation
- [Xcode Previews — Apple Developer](https://developer.apple.com/documentation/swiftui/previews-in-xcode)
