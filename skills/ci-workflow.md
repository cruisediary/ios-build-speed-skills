# ci-workflow

Audits GitHub Actions workflows for runner version, concurrency configuration, and job structure to reduce iOS CI build time.

## TRIGGER

Invocation: `/ci-workflow`
Description: Audit GitHub Actions workflows for runner version, concurrency, and job structure to reduce iOS CI build time.

## ENVIRONMENT

Follow `skills/core/detect-environment.md`.

Detect GitHub Actions workflows:
```bash
ls .github/workflows/*.yml 2>/dev/null
```

If no workflow files found: print `No GitHub Actions workflows found. Create a workflow file at .github/workflows/ first.` and exit.

If workflow files found but none contain `xcodebuild` or `swift build`: print `⚠️ No Xcode build steps detected in workflow files. Proceeding with structural audit only.`

Note: This skill audits YAML structure only — it does not require a minimum Xcode version.

## AUDIT

Scan each `.github/workflows/*.yml` file.

**Runner checks:**

| Finding | Condition | Severity |
|---|---|---|
| Outdated runner | `runs-on: macos-12`, `macos-13`, or `macos-14` | 🔴 Critical |
| Unpinned runner | `runs-on: macos-latest` | 🟡 Medium |
| Xcode version not pinned | No `xcode-select`, `DEVELOPER_DIR`, or `xcodes` step | 🟡 Medium |
| No concurrency group | Top-level or job-level `concurrency:` missing | 🟠 High |

**Structure checks:**

| Finding | Condition | Severity |
|---|---|---|
| Build and test in same job | Single job handles both compile and test steps | 🟠 High |
| No job timeout | `timeout-minutes:` absent on jobs with `xcodebuild` | 🟡 Medium |

Detect with:
```bash
grep -l "macos-12\|macos-13\|macos-14\|macos-latest" .github/workflows/*.yml 2>/dev/null
grep -rL "timeout-minutes" .github/workflows/ 2>/dev/null
grep -rL "xcode-select\|DEVELOPER_DIR\|xcodes" .github/workflows/ 2>/dev/null
```

For the concurrency check: inspect whether a `concurrency:` key exists at the top level (indented 0 spaces, directly under the workflow root) or at `jobs.<job_id>.concurrency:`. A substring grep cannot distinguish YAML structural levels — read the YAML directly.

## REPORT

Follow `skills/core/report-formatter.md` format. Report per workflow file.

```
── .github/workflows/ci.yml ──

🔴 [Critical] runs-on: macos-14 — outdated runner
Impact:         Older hardware ceiling; misses Xcode 16 toolchain default on macos-15
Recommendation: Upgrade to macos-15 and pin Xcode version with xcode-select
Example:        examples/ci-workflow/

🟠 [High] No concurrency group configured
Impact:         Duplicate runs on the same branch consume runner minutes and extend feedback time
Recommendation: Add concurrency group with branch-aware cancel-in-progress
Example:        examples/ci-workflow/
```

## ACTION

Mode: `mixed`

1. Print the full report.
2. If no findings, stop.
3. List proposed auto-apply changes:
   ```
   Proposed changes:
   - .github/workflows/ci.yml: macos-14 → macos-15
   - .github/workflows/ci.yml: add concurrency group
   - .github/workflows/ci.yml: add timeout-minutes: 30
   ```
4. Print:
   ```
   ⚠️ Upgrading the runner changes the default Xcode version. Pin your Xcode version
   (see guided recommendations below) before pushing this change.
   ```
5. Print: `Apply these changes? [y/N]`
6. If yes:
   a. Follow `skills/core/git-backup.md` before modifying files.
   b. Apply to each affected workflow file:
      - Replace `macos-12`, `macos-13`, `macos-14` with `macos-15` in `runs-on:`
      - Add at top level (before `jobs:`):
        ```yaml
        concurrency:
          group: ${{ github.workflow }}-${{ github.ref }}
          cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}
        ```
        `cancel-in-progress: true` on all branches would silently cancel main branch runs — this expression limits cancellation to PR and feature branches only.
      - Add `timeout-minutes: 30` to each job missing it.
        Note: 30 minutes is a safe default for build jobs. Test jobs may require higher values — review after applying.
   c. Print: `✅ Workflow updated. Review timeout values for test jobs before pushing.`
7. If no: print `No changes made.`

**Guided recommendations** (printed after the auto-apply section regardless of [y/N] choice):

**Xcode version pinning:**
```
Add this step before your xcodebuild step:
  - name: Select Xcode
    run: sudo xcode-select -s /Applications/Xcode_16.2.app/Contents/Developer
```

**Build/test job separation:**
```
Split your single job into two:

  build:
    runs-on: macos-15
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - name: Build
        run: xcodebuild build -scheme MyApp -destination 'generic/platform=iOS Simulator'

  test:
    runs-on: macos-15
    needs: build
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@v4
      - # Add cache restoration here to reuse build artifacts — see /ci-cache
      - name: Test
        run: xcodebuild test -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

## COMPOSABILITY

Recommended: run `/ci-cache` before `/ci-workflow` so caching is in place before restructuring jobs. The two skills are otherwise independent — they touch different YAML keys and can be run in either order without conflict.

Independent from all local skills (`/xcode-settings`, `/build-settings`, `/concurrency-settings`).

## EXAMPLES

See `examples/ci-workflow/` for before/after GitHub Actions workflow files.

## REFERENCES

- [GitHub Actions: GitHub-hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners/about-github-hosted-runners) — macOS runner versions and hardware specs
- [GitHub Actions: Workflow syntax — concurrency](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#concurrency) — concurrency group syntax and cancel-in-progress
- [GitHub Actions: Workflow syntax — timeout-minutes](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions#jobsjob_idtimeout-minutes) — per-job timeout to prevent hung builds from consuming runner minutes
