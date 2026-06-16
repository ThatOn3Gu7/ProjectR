# Contributing to ProjectR

Thank you for your interest in contributing! ProjectR is available on both **GitHub** and **GitLab** — contributions are welcome from either platform.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Running Tests](#running-tests)
- [Linting](#linting)
- [Commit Convention](#commit-convention)
- [Branch Naming](#branch-naming)
- [Opening a Pull / Merge Request](#opening-a-pull--merge-request)
- [Code Style](#code-style)

---

## Getting Started

1. **Fork** the repository on [GitHub](https://github.com/ThatOn3Gu7/ProjectR) or [GitLab](https://gitlab.com/Thaton3gu7/ProjectR) and clone your fork:
   ```bash
   git clone https://github.com/<your-username>/ProjectR.git
   # or
   git clone https://gitlab.com/<your-username>/ProjectR.git
   cd ProjectR
   ```

2. Make sure the entry-point scripts are executable:
   ```bash
   chmod +x main.sh setup.sh
   ```

3. Install runtime dependencies (Debian/Ubuntu):
   ```bash
   sudo apt-get install -y shellcheck bats git bash
   ```

---

## Running Tests

ProjectR uses [bats-core](https://github.com/bats-core/bats-core) for the main test suite and also includes a plain Bash smoke test for the source-safe library API.

```bash
bats tests/suite.bats
bash tests/library_smoke.sh
```

If your change touches `lib/projectr.sh`, registry lookup, plugin loading, dry-run planning, or source-time behavior, always run `tests/library_smoke.sh` even if `bats` is not installed locally.

All tests must pass before a pull/merge request can be accepted.

---

## Linting

All shell scripts must pass [shellcheck](https://www.shellcheck.net/) at the `warning` severity level:

```bash
find . -name '*.sh' -not -path './.git/*' | xargs shellcheck --severity=warning
```

Fix any reported warnings before submitting your changes.

---

## Commit Convention

ProjectR follows the [Conventional Commits](https://www.conventionalcommits.org/) specification.

| Type     | When to use                                      |
|----------|--------------------------------------------------|
| `feat`     | A new feature                                    |
| `fix`      | A bug fix                                        |
| `docs`     | Documentation changes only                       |
| `refactor` | Code change that is neither a fix nor a feature  |
| `ci`       | Changes to CI/CD configuration                   |
| `chore`    | Maintenance tasks (deps, tooling, etc.)          |
| `test`     | Adding or updating tests                         |

**Examples:**
```
feat: add rollback support to uninstaller
fix: resolve shellcheck SC2086 warning in installer.sh
docs: update module reference for lib/system
```

---

## Branch Naming

Use descriptive, kebab-case branch names prefixed with the change type:

```
feat/add-rollback-support
fix/shellcheck-warnings-installer
docs/update-module-reference
chore/update-dependencies
```

---

## Opening a Pull / Merge Request

ProjectR accepts contributions via **GitHub Pull Requests** and **GitLab Merge Requests**.

1. Push your branch to your fork.
2. Open a Pull Request (GitHub) or Merge Request (GitLab) against the `master` branch.
3. Fill in the description explaining **what** changed and **why**.
4. Ensure CI passes — GitHub Actions and GitLab CI both run shellcheck, bats, and script validation.
5. Request a review if needed.

> **Note:** Both platforms mirror the same codebase. You only need to submit on one.

---

## Code Style

- All scripts must start with `#!/usr/bin/env bash`.
- Enable strict mode where appropriate (`set -euo pipefail`) — see `lib/core/strict_mode.sh`.
- Keep functions small and single-purpose.
- Use `local` for all variables inside functions.
- Prefer `[[ ]]` over `[ ]` for conditionals.
- Avoid hardcoded paths; use variables defined in `lib/data/config.sh`.
- All new scripts must be shellcheck-clean at the `warning` level.
