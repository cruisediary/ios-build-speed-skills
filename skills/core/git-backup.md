# git-backup (core utility)

> Internal utility. Not user-invocable. Referenced by `apply with confirmation` skills in their ACTION section before any file modification.

When a skill instructs you to "follow skills/core/git-backup.md before any write", execute these steps in order:

## Steps

### 1. Verify git repository

Run:
```bash
git rev-parse --is-inside-work-tree
```

If this command fails (exit code non-zero), **stop the ACTION phase** and print:
```
❌ Not a git repository.
ios-build-speed skills that modify files require a git repository.
To initialize one: git init
To proceed without a checkpoint, run the commands manually as shown in the EXAMPLES section.
```

### 2. Check for uncommitted changes

Run:
```bash
git status --porcelain
```

If output is non-empty (there are staged or unstaged changes), print:
```
🟠 Note: You have uncommitted changes. They will be included in the stash checkpoint
and restored with git stash pop if you need to undo.
```

Do not block — proceed to step 3.

### 3. Create stash checkpoint

Run:
```bash
git stash push --include-untracked -m "ios-build-speed: pre-<skill-name> checkpoint"
```

Replace `<skill-name>` with the name of the invoking skill (e.g., `pre-type-annotations`, `pre-protocol-separation`).

The `--include-untracked` flag ensures that new files created by this skill (e.g., `UserServiceProtocol.swift`) are captured in the stash and will be removed on `git stash pop`.

After the stash is created, print:
```
✅ Checkpoint created.
To undo all changes made by this skill: git stash pop
```

### 4. Proceed with changes

The skill's ACTION steps may now modify files safely.

## Sequential skill runs

When running multiple `apply with confirmation` skills in sequence, each skill creates its own stash entry. `git stash list` will show all entries. Each `git stash pop` undoes one skill's changes in reverse order (most recent first).

**Recommendation:** Commit (or discard) changes after each skill before running the next one. This keeps the stash clean and makes it obvious which changes belong to which skill.

## REFERENCES

- [git stash — Git documentation](https://git-scm.com/docs/git-stash) — `--include-untracked` flag and stash stack behaviour
