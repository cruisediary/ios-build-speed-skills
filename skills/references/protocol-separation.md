# protocol-separation

Detects protocols defined alongside their implementations and extracts them into dedicated files to minimize recompilation blast radius.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

## AUDIT

Scan all `.swift` files in the project (excluding `.build/`, `Pods/`, `Carthage/`):

**Finding 1: Protocol defined in the same file as its conforming type**

Look for files where both:
- A `protocol XxxProtocol` or `protocol Xxx` definition exists, AND
- A `class Xxx`, `struct Xxx`, or `extension Xxx: XxxProtocol` exists in the same file

Flag each such file as a finding.

**Finding 2: Large files (>300 lines)**

Count lines in each `.swift` file. Files over 300 lines are likely to trigger wide recompilation when changed.

Report the top 5 largest files by line count.

**Finding 3: Associated types and typealiases in implementation files**

Look for `typealias` declarations in files that also contain class/struct implementations. These increase the type-checker surface area for any file that imports the module.

## REPORT

Follow `../core/report-formatter.md` format.

```
🟠 [High] UserService.swift defines protocol and implementation in the same file
Impact:         Any change to UserService implementation forces recompilation of all files that import the protocol
Recommendation: Extract UserServiceProtocol to UserServiceProtocol.swift
Example:        examples/protocol-separation/

🟡 [Medium] NetworkManager.swift is 487 lines
Impact:         Large files have a wide recompilation blast radius when changed
Recommendation: Consider splitting into NetworkManager.swift + NetworkManagerProtocol.swift
Example:        examples/protocol-separation/
```

## ACTION

Mode: `apply with confirmation`

For each Finding 1 (protocol co-located with implementation):

1. Print the proposed transformation:
   ```
   Proposed: Extract protocol from UserService.swift
     Create: UserServiceProtocol.swift (protocol definition)
     Modify: UserService.swift (remove protocol, keep implementation)
   ```

2. Ask: `Apply this extraction? [y/N]`

3. If yes:
   a. Follow `../core/git-backup.md` before the first file modification (run once, not per-file).
   b. Create `<FileName>Protocol.swift` with:
      - The same `import` statements as the original file
      - The protocol definition block, verbatim
      - No other content
   c. Remove the protocol definition from the original file.
   d. Print: `✅ Extracted: <FileName>Protocol.swift`

For Finding 2 (large files), print guidance only — do not auto-split large files.

## COMPOSABILITY

For best results, run `/modular-architecture` first. Protocol separation reduces the recompilation blast radius within a module; module boundaries determine which modules are affected at all. Doing module decomposition first means you extract protocols in the right module context.

## EXAMPLES

See `examples/protocol-separation/` for before/after Swift files.

## REFERENCES

- [WWDC 2022 — Improve app size and runtime performance](https://developer.apple.com/videos/play/wwdc2022/110363/) — protocol witness tables and build-time implications
- [WWDC 2023 — Demystify explicitly built modules](https://developer.apple.com/videos/play/wwdc2023/10171/) — how Swift isolates recompilation to changed modules
- [Swift Evolution SE-0258 — Property wrappers](https://github.com/apple/swift-evolution/blob/main/proposals/0258-property-wrappers.md) — illustrates protocol/implementation co-location patterns that add type-checker load
- [Improving your Swift build time — Alejandro Ramirez](https://medium.com/swift-programming/improving-your-swift-build-time-a34af8a31ef8) — practical protocol extraction techniques
