# ci-cache

Audits CI/CD configuration files and provides platform-specific instructions for caching SPM packages, derived data, and build artifacts to reduce CI build times.

## TRIGGER

Invocation: `/ci-cache`
Description: Audit CI configuration and add caching for SPM packages and derived data.

## ENVIRONMENT

Follow `skills/core/detect-environment.md`.

If Xcode < 14: display 🔴 warning, skip all automated changes, print recommendations as guidance only.

Detect CI configuration files:
- GitHub Actions: `.github/workflows/*.yml`
- Bitrise: `bitrise.yml`
- CircleCI: `.circleci/config.yml`
- Xcode Cloud: `ci_scripts/` directory

If no CI configuration is found, print:
```
No CI configuration detected. Create a CI workflow first, then re-run /ci-cache.
Supported platforms: GitHub Actions, Bitrise, CircleCI, Xcode Cloud.
```

## AUDIT

For each CI platform found, check for:

**1. SPM package cache**
- GitHub Actions: `actions/cache` step targeting `~/Library/Caches/org.swift.swiftpm/` or `.build/`
- Bitrise: `cache-push` / `cache-pull` steps for `.build/`
- CircleCI: `restore_cache` / `save_cache` steps for `.build/`

**2. Derived data cache**
- Any platform: caching `~/Library/Developer/Xcode/DerivedData` between runs

**3. Simulator boot optimization**
- Check if workflow boots the simulator before running tests (avoids boot overhead in test step)

Flag each missing cache step per platform.

## REPORT

Follow `skills/core/report-formatter.md` format.

Report per platform:

```
── GitHub Actions (.github/workflows/ci.yml) ──

🔴 [Critical] No SPM package cache configured
Impact:         SPM resolves and compiles all dependencies from scratch on every run (can add 3–10 minutes)
Recommendation: Add actions/cache step for ~/.spm/cache with Package.resolved as cache key
Example:        examples/ci-cache/

🟠 [High] No derived data cache configured
Impact:         Xcode recompiles unchanged modules on every CI run
Recommendation: Add actions/cache step for ~/Library/Developer/Xcode/DerivedData
Example:        examples/ci-cache/
```

## ACTION

Mode: `guided`

This skill prints numbered instructions per platform. It does not modify CI files automatically because cache key strategies, runner environments, and workflow structure vary significantly across teams and projects.

Print platform-specific guidance:

**GitHub Actions:**
```
Step 1: Add the following cache steps to your workflow BEFORE the xcodebuild step:

    - name: Cache SPM packages
      uses: actions/cache@v4
      with:
        path: |
          ~/Library/Caches/org.swift.swiftpm
          .build
        key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
        restore-keys: |
          ${{ runner.os }}-spm-

    - name: Cache DerivedData
      uses: actions/cache@v4
      with:
        path: ~/Library/Developer/Xcode/DerivedData
        key: ${{ runner.os }}-deriveddata-${{ hashFiles('**/*.swift', '**/*.m', '**/*.h') }}
        restore-keys: |
          ${{ runner.os }}-deriveddata-

Step 2: Ensure Package.resolved is committed to your repository (required for stable cache keys).
Step 3: See examples/ci-cache/ for a complete before/after workflow example.
```

**Bitrise:**
```
Step 1: Add cache-pull before your Xcode build step:
  - cache-pull@2: {}

Step 2: Add cache-push after your Xcode build step:
  - cache-push@2:
      inputs:
      - cache_paths: |
          .build
          ~/Library/Developer/Xcode/DerivedData

Step 3: See Bitrise documentation for cache invalidation strategies.
```

**CircleCI:**
```
Step 1: Add restore_cache before xcodebuild:
  - restore_cache:
      keys:
        - spm-{{ checksum "Package.resolved" }}
        - spm-

Step 2: Add save_cache after xcodebuild:
  - save_cache:
      key: spm-{{ checksum "Package.resolved" }}
      paths:
        - .build
        - ~/Library/Developer/Xcode/DerivedData
```

**Xcode Cloud:**
```
Xcode Cloud manages derived data caching automatically between workflows.
For SPM, ensure your Package.resolved is committed.
Custom cache paths are not configurable in Xcode Cloud — no action required.
```

## COMPOSABILITY

The DerivedData cache path used in CI depends on the `DerivedDataLocationStyle` Xcode preference. Run `/xcode-settings` first to confirm (or set) the DerivedData location, then configure CI caching for that path.

**Package.resolved:** CI cache keys for SPM (e.g., `hashFiles('**/Package.resolved')`) require `Package.resolved` to be committed. If your project uses SPM, ensure this file is in version control. See `/modular-architecture` for guidance on introducing `Package.swift`.

## EXAMPLES

See `examples/ci-cache/` for GitHub Actions workflow before/after.

## REFERENCES

- [actions/cache — GitHub Marketplace](https://github.com/marketplace/actions/cache) — `actions/cache@v4` documentation and cache key strategies
- [Bitrise cache-push and cache-pull steps](https://devcenter.bitrise.io/en/builds/caching.html) — Bitrise cache step reference
- [CircleCI caching dependencies](https://circleci.com/docs/caching/) — `restore_cache` / `save_cache` documentation
- [Xcode Cloud overview — Apple Developer](https://developer.apple.com/documentation/xcode/xcode-cloud) — what Xcode Cloud caches automatically vs what requires configuration
