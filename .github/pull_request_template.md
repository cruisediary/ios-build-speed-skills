## Summary

<!-- What does this PR change? -->

## Skill authoring checklist (new/modified skills only)

- [ ] Eight-section structure: TRIGGER, ENVIRONMENT, AUDIT, REPORT, ACTION, EXAMPLES, COMPOSABILITY, REFERENCES
- [ ] Invocation name is lowercase, hyphenated, unique
- [ ] Action mode is `apply with confirmation` or `guided`
- [ ] `apply with confirmation` skills reference `skills/core/git-backup.md` in ACTION
- [ ] Before/after examples in `examples/<skill-name>/`
- [ ] Version-adaptive: behavior defined for Xcode 14, 15, 16+
- [ ] No references to `docs/superpowers/`

## Testing

**Xcode versions tested:**
- [ ] Xcode 16+
- [ ] Xcode 15
- [ ] Xcode 14

<!-- Describe what you verified and how. Paste any relevant output or observations. -->
