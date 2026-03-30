# Contributing to ios-build-speed-skills

## Adding a new skill

1. Open an issue using the [New Skill template](.github/ISSUE_TEMPLATE/new_skill.md) — describe the optimization, target audience, and proposed action mode.
2. Fork the repository and create a branch: `skill/<skill-name>`
3. Create `skills/references/<skill-name>.md` following the [Skill Contract](#skill-contract) exactly.
4. Add the new skill to the Available skills table in `skills/ios-build-speed/SKILL.md`.
5. Add `examples/<skill-name>/before.*` and `examples/<skill-name>/after.*`.
6. Verify your skill against the [authoring checklist](#skill-authoring-checklist).
7. Open a pull request using the PR template.

All skill text must be written in English. Commit in small, meaningful units — one logical change per commit.

---

## Skill Contract

Every skill must contain exactly these seven sections in this order:

```markdown
## ENVIRONMENT
Follow ../core/detect-environment.md.
If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

## AUDIT
<what to scan, what constitutes a finding>

## REPORT
Follow skills/core/report-formatter.md format.
List all findings with severity, impact, and recommendation.

## ACTION
Mode: apply with confirmation | guided
<specific steps>
# apply with confirmation skills must reference ../core/git-backup.md before any write

## COMPOSABILITY
<cross-references to related skills and recommended run order>

## EXAMPLES
See examples/<skill-name>/ for before/after.

## REFERENCES
- [Source title](url) — one-line description
```

### Action modes

| Mode | When to use |
|---|---|
| `apply with confirmation` | Changes are mechanical and well-defined (flag edits, file splits, annotation insertions) |
| `guided` | Changes require architectural judgment (module boundaries, CI pipeline design) |

---

## Skill authoring checklist

Before opening a PR, verify:

- [ ] Seven-section structure present: ENVIRONMENT, AUDIT, REPORT, ACTION, COMPOSABILITY, EXAMPLES, REFERENCES
- [ ] Skill file created at `skills/references/<name>.md` and entry added to `skills/ios-build-speed/SKILL.md`
- [ ] Action mode is `apply with confirmation` or `guided`
- [ ] `apply with confirmation` skills reference `../core/git-backup.md` in ACTION
- [ ] Before/after examples provided in `examples/<skill-name>/` matching the skill's domain
- [ ] Version-adaptive: behavior explicitly defined for Xcode 14, 15, and 16+
- [ ] No references to `docs/superpowers/` (development artifact)

---

## Core utilities

The `skills/core/` directory contains three internal utilities used by all category skills.
Do not create user-invocable skills in `skills/core/`.

| File | Purpose |
|---|---|
| `../core/detect-environment.md` | Xcode/Swift version detection, package manager detection |
| `../core/git-backup.md` | git stash checkpoint before modifying files |
| `../core/report-formatter.md` | Severity levels and per-finding output format |

---

## Reporting bugs

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md).
