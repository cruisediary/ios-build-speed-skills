# type-annotations

Detects expensive type inference sites and inserts explicit type annotations to reduce Swift compiler type-checking overhead.

## ENVIRONMENT

Follow `../core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

## AUDIT

Scan all `.swift` files (excluding `.build/`, `Pods/`, `Carthage/`) for these patterns:

**Pattern 1: Closures without explicit parameter and return type annotations**

Look for closures passed to `.map`, `.filter`, `.reduce`, `.flatMap`, `.compactMap`, `.sorted`, `forEach` that use `$0`/`$1` shorthand or have no parameter types declared.

Flag: any closure in a chain of 2+ higher-order function calls.

**Pattern 2: `let`/`var` bindings to constructor calls that have unambiguous types**

Look for patterns like:
- `let x = [String]()` → type is determinable: `let x: [String] = []`
- `let dict = [String: Int]()` → `let dict: [String: Int] = [:]`
- `var items = Array<Item>()` → `var items: [Item] = []`

**Pattern 3: Chained functional transformations without intermediate type hints**

Look for chains of 3+ chained calls on a single expression without an intermediate type annotation.

**Pattern 4: Complex expressions that exceed the type checker's heuristic limit**

Look for these patterns that cause exponential type-checker growth (from WWDC 2016 "Understanding Swift Performance"):
- 4+ `String` values joined with `+` operator — use string interpolation instead
- Ternary expressions containing type coercions (`as`, `as?`, `as!`)
- Nil-coalescing chains of 3+ (`a ?? b ?? c ?? d`)
- Array/dictionary literals with 10+ heterogeneous elements

Flag each occurrence. These are guidance-only findings (🟡 Medium) — the fix requires manual restructuring.

**Pattern 5: Missing compiler diagnostic flags**

Check `OTHER_SWIFT_FLAGS` in `project.pbxproj` or `.xcconfig` for:
- `-Xfrontend -warn-long-function-bodies=200`
- `-Xfrontend -warn-long-expression-type-checking=200`

If absent, flag as 🔵 Low — these flags surface slow-compiling code during development.

**Important scope:** This skill only auto-applies Patterns 1 and 2 (types that are syntactically determinable). Patterns 3, 4, and 5 are guidance only.

## REPORT

Follow `../core/report-formatter.md` format.

```
🟠 [High] 3 closures in UserListView.swift lack explicit type annotations (line 45, 67, 89)
Impact:         Swift type checker must infer closure types from context, increasing compile time for this file
Recommendation: Add explicit parameter and return type annotations to each closure
Example:        examples/type-annotations/

🟡 [Medium] Complex expression at NetworkManager.swift:112 — type requires full inference
Impact:         Cannot be safely auto-annotated; type is not determinable from expression shape alone
Recommendation: Manually add: let result: <YourType> = ...
Example:        examples/type-annotations/
```

## ACTION

Mode: `apply with confirmation`

For Pattern 1 (unannotated closures) and Pattern 2 (constructor bindings):

1. Print all proposed annotation insertions with file + line numbers.
2. Ask: `Apply these annotations? [y/N]`
3. If yes:
   a. Follow `../core/git-backup.md` before the first modification.
   b. Insert annotations at the identified sites.
   c. Print: `✅ Annotations applied to N sites across M files.`

For Patterns 3, 4 (🟡 Medium complex expressions): print guidance only, do not auto-apply.

For Pattern 5 (🔵 Low missing diagnostic flags): print the exact `OTHER_SWIFT_FLAGS` entries to add — user applies manually.

## COMPOSABILITY

This is a refinement pass. Run `/modular-architecture` and `/protocol-separation` first to establish structural boundaries. Annotating types in a monolithic target has diminishing returns if the overall recompilation blast radius is still large.

## EXAMPLES

See `examples/type-annotations/` for before/after Swift files.

## REFERENCES

- [Whole-module optimisation and incremental compilation — Swift.org blog](https://www.swift.org/blog/whole-module-optimizations/) — explains how type inference cost scales with module size
- [WWDC 2016 — Understanding Swift Performance](https://developer.apple.com/videos/play/wwdc2016/416/) — type inference overhead, complex expressions, and annotation strategies
- [Swift compiler performance — apple/swift wiki](https://github.com/apple/swift/blob/main/docs/CompilerPerformance.md) — canonical reference for type-checker cost and mitigation
- [Reducing Swift build times — Krzysztof Zabłocki](https://www.merowing.info/2021/12/reducing-swift-build-times/) — real-world case study with before/after benchmarks
