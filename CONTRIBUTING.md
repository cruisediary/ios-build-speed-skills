# Contributing to ios-build-speed-skills

## Adding a new skill

1. Open an issue using the [New Skill template](.github/ISSUE_TEMPLATE/new_skill.md) — describe the optimization, target audience, and proposed action mode.
2. Fork the repository and create a branch: `skill/<skill-name>`
3. Create `skills/<skill-name>.md` following the [Skill Contract](#skill-contract) exactly.
4. Add `examples/<skill-name>/before.*` and `examples/<skill-name>/after.*`.
5. Verify your skill against the [authoring checklist](#skill-authoring-checklist).
6. Open a pull request using the PR template.

All skill text must be written in English. Commit in small, meaningful units — one logical change per commit.

---

## Skill Contract

Every skill must contain exactly these eight sections in this order:

```markdown
## TRIGGER
Invocation: /skill-name
Description: <user-facing one-liner>

## ENVIRONMENT
Follow skills/core/detect-environment.md.
If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

## AUDIT
<what to scan, what constitutes a finding>

## REPORT
Follow skills/core/report-formatter.md format.
List all findings with severity, impact, and recommendation.

## ACTION
Mode: apply with confirmation | guided
<specific steps>
# apply with confirmation skills must reference skills/core/git-backup.md before any write

## EXAMPLES
See examples/<skill-name>/ for before/after.

## COMPOSABILITY
<cross-references to related skills and recommended run order>

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

- [ ] Eight-section structure present: TRIGGER, ENVIRONMENT, AUDIT, REPORT, ACTION, EXAMPLES, COMPOSABILITY, REFERENCES
- [ ] Invocation name is lowercase, hyphenated, and unique across all skills
- [ ] Action mode is `apply with confirmation` or `guided`
- [ ] `apply with confirmation` skills reference `skills/core/git-backup.md` in ACTION
- [ ] Before/after examples provided in `examples/<skill-name>/` matching the skill's domain
- [ ] Version-adaptive: behavior explicitly defined for Xcode 14, 15, and 16+
- [ ] No references to `docs/superpowers/` (development artifact)

---

## Core utilities

The `skills/core/` directory contains three internal utilities used by all category skills.
Do not create user-invocable skills in `skills/core/`.

| File | Purpose |
|---|---|
| `skills/core/detect-environment.md` | Xcode/Swift version detection, package manager detection |
| `skills/core/git-backup.md` | git stash checkpoint before modifying files |
| `skills/core/report-formatter.md` | Severity levels and per-finding output format |

---

## Reporting bugs

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md).
