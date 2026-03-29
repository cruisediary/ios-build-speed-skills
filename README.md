# ios-build-speed-skills

Claude Code skills that audit and fix common causes of slow iOS/Xcode build times.

Each skill scans your project, reports findings by severity, and applies fixes with your confirmation.

## Skills

### IDE & Build Settings

| Skill | What it does |
|---|---|
| `/xcode-settings` | Xcode IDE preferences — concurrent tasks, DerivedData location, indexing |
| `/build-settings` | Build flags — `SWIFT_COMPILATION_MODE`, `EAGER_LINKING`, explicit modules, sanitizers |
| `/script-phases` | Run Script phases — input/output declarations, sandboxing, phase ordering |
| `/link-settings` | Linker config — static vs dynamic frameworks, `EXPORTED_SYMBOLS_FILE`, unused deps |

### Architecture

| Skill | What it does |
|---|---|
| `/modular-architecture` | SPM module boundaries — reduce recompilation blast radius |
| `/protocol-separation` | Extract protocols to dedicated files — break unnecessary cross-file dependencies |
| `/type-annotations` | Explicit type annotations — reduce type-inference work at compile time |

### Caching

| Skill | What it does |
|---|---|
| `/xcode-cache` | Local cache — llbuild, ccache, `.gitignore`, Xcode 16 compilation cache |
| `/ci-cache` | CI/CD cache — DerivedData and SPM cache configuration for GitHub Actions, Bitrise, etc. |

## Install

**One-liner** (installs globally, available in all Claude Code sessions):
```sh
curl -fsSL https://raw.githubusercontent.com/cruisediary/ios-build-speed-skills/main/install.sh | bash -s -- --global
```

**Or clone and run interactively:**
```sh
git clone https://github.com/cruisediary/ios-build-speed-skills.git
cd ios-build-speed-skills
./install.sh
```

<details>
<summary>All install options</summary>

```sh
./install.sh              # Interactive: prompts global vs local
./install.sh --global     # Install to ~/.claude/skills/ios-build-speed/
./install.sh --local      # Install to ./.claude/skills/ios-build-speed/
./install.sh --force      # Overwrite without prompt
./install.sh --uninstall --global
./install.sh --uninstall --local
```
</details>

Restart Claude Code after installing to activate the skills.

## Usage

Open Claude Code in your Xcode project directory and invoke any skill:

```
/build-settings
```

Every skill follows the same flow:
1. Detects Xcode/Swift version and package manager
2. Audits the project for relevant issues
3. Reports findings with severity levels (🔴 Critical → 🔵 Low)
4. Proposes changes and asks for confirmation before modifying any files

## Recommended order

Skills build on each other. For a full audit, run them in this sequence:

| Step | Skill | Depends on |
|---|---|---|
| 1 | `/xcode-settings` | — |
| 2 | `/build-settings` | — |
| 3 | `/script-phases` | — |
| 4 | `/modular-architecture` | — |
| 5 | `/link-settings` | Step 4 module structure |
| 6 | `/protocol-separation` | Step 4 module structure |
| 7 | `/type-annotations` | Step 6 protocol boundaries |
| 8 | `/xcode-cache` | Steps 1–7 in place |
| 9 | `/ci-cache` | Step 1 DerivedData location |

You can run individual skills in any order — the table above is the recommended sequence when starting from scratch.

## Safety

All file-modifying skills create a git stash checkpoint before making changes:
```
ios-build-speed: pre-<skill-name> checkpoint
```

To undo all changes made by a skill:
```sh
git stash pop
```

## Version support

| Xcode | Swift | Support |
|---|---|---|
| 16+ | 6+ | Full |
| 15 | 5.9+ | Full |
| 14 | 5.7+ | Core features |
| < 14 | < 5.7 | Guidance only (no automated changes) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — [cruisediary](https://github.com/cruisediary)
