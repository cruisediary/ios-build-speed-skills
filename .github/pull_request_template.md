## Summary

<!-- What does this PR change? -->

## Skill authoring checklist (new/modified skills only)

- [ ] Seven-section structure: ENVIRONMENT, AUDIT, REPORT, ACTION, EXAMPLES, COMPOSABILITY, REFERENCES
- [ ] Skill file created at `skills/references/<name>.md` and entry added to `skills/ios-build-speed/SKILL.md`
- [ ] Action mode is `apply with confirmation` or `guided`
- [ ] `apply with confirmation` skills reference `../core/git-backup.md` in ACTION
- [ ] Before/after examples in `examples/<skill-name>/`
- [ ] Version-adaptive: behavior defined for Xcode 14, 15, 16+
- [ ] No references to `docs/superpowers/`

## Testing

**Xcode versions tested:**
- [ ] Xcode 16+
- [ ] Xcode 15
- [ ] Xcode 14

<!-- Describe what you verified and how. Paste any relevant output or observations. -->
