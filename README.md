# ios-build-speed-skills

A collection of [Claude Code](https://claude.ai/code) skills for reducing iOS/Xcode build times.

## What's included

| Skill | Invocation | Mode | What it does |
|---|---|---|---|
| xcode-settings | `/xcode-settings` | Apply with confirmation | Xcode IDE preferences via `defaults write` |
| build-settings | `/build-settings` | Apply with confirmation | Build flag optimisation (`SWIFT_COMPILATION_MODE`, `EAGER_LINKING`, explicit modules, etc.) |
| modular-architecture | `/modular-architecture` | Guided | SPM module boundary recommendations |
| protocol-separation | `/protocol-separation` | Apply with confirmation | Extract protocols to dedicated files |
| type-annotations | `/type-annotations` | Apply with confirmation | Explicit type annotations and complex expression detection |
| script-phases | `/script-phases` | Apply with confirmation | Run Script phase input/output declarations and sandboxing |
| link-settings | `/link-settings` | Apply with confirmation | Linker configuration, static vs dynamic frameworks, unused deps |
| xcode-cache | `/xcode-cache` | Apply with confirmation | llbuild, ccache, `.gitignore`, Xcode 16 compilation cache |
| ci-cache | `/ci-cache` | Guided | CI/CD pipeline cache instructions |

## Install

**Global install** (available in all Claude Code sessions):
```sh
curl -fsSL https://raw.githubusercontent.com/cruisediary/ios-build-speed-skills/main/install.sh | bash -s -- --global
```

Or clone and run locally:
```sh
git clone https://github.com/cruisediary/ios-build-speed-skills.git
cd ios-build-speed-skills
./install.sh
```

**Options:**
```sh
./install.sh              # Interactive: prompts global vs local
./install.sh --global     # Install to ~/.claude/skills/ios-build-speed/
./install.sh --local      # Install to ./.claude/skills/ios-build-speed/
./install.sh --force      # Overwrite without prompt (install only)
./install.sh --uninstall --global
./install.sh --uninstall --local
```

After installing, restart Claude Code to activate skills.

## Usage

Inside Claude Code, invoke any skill by name:

```
/xcode-settings
```

Each skill will:
1. Detect your Xcode/Swift version and package manager
2. Audit your project for the relevant issues
3. Show findings with severity levels (🔴 Critical → 🔵 Low)
4. Propose changes and ask for confirmation before modifying any files

## Recommended order

Skills build on each other. For a full project audit, run them in this order:

| Step | Skill | Why |
|---|---|---|
| 1 | `/xcode-settings` | Sets DerivedData location — needed by `/xcode-cache` and `/ci-cache` |
| 2 | `/build-settings` | Compile flag optimisation — fast win before structural changes |
| 3 | `/script-phases` | Eliminate redundant script runs — easy win alongside build settings |
| 4 | `/modular-architecture` | Largest structural change — do this before protocol or type work |
| 5 | `/link-settings` | Linker optimisation — informed by module structure from step 4 |
| 6 | `/protocol-separation` | Reduce blast radius within modules established in step 4 |
| 7 | `/type-annotations` | Refinement pass — most effective after module boundaries are stable |
| 8 | `/xcode-cache` | Cache configuration — benefits from steps 1–7 being in place |
| 9 | `/ci-cache` | CI caching — depends on DerivedData location from step 1 |

You can run individual skills in any order. The table above is the recommended sequence when starting from scratch.

## Safety

All file-modifying skills create a `git stash` checkpoint before making changes:
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
