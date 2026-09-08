---
name: verification-loop
description: "A comprehensive verification system for OpenCode sessions. Use when verifying a session's work before claiming it is complete."
license: MIT
metadata:
  origin: ECC
---

# Verification Loop Skill

A comprehensive verification system for OpenCode sessions.

## When to Use

Invoke this skill:
- After completing a feature or significant code change
- Before creating a PR
- When you want to ensure quality gates pass
- After refactoring

## Verification Phases

### Phase 1: Build Verification

Run the project build and confirm it succeeds:

```bash
npm run build
```

If build fails, STOP and fix before continuing.

### Phase 2: Type Check

```bash
# TypeScript projects
npx --no-install tsc --noEmit

# Python projects
pyright .
```

Report all type errors. Fix critical ones before continuing.

### Phase 3: Lint Check

Prefer the package's `lint-check` tool to detect the project's linter and return the
check/fix command. Alternatively:

```bash
# JavaScript/TypeScript
npm run lint

# Python
ruff check .
```

### Phase 4: Test Suite

Use the package's `run-tests` tool to detect and run the test suite (with coverage when
available), then `check-coverage` to compare against the threshold.

Target: 80% coverage minimum.

Report:
- Total tests: X
- Passed: X
- Failed: X
- Coverage: X%

### Phase 5: Security Scan

Use the package's `security-audit` tool (covers dependency vulnerabilities, secret
scanning, and common code-security issues). For a quick console.log sweep of edited
JavaScript/TypeScript files, rely on the plugin's `file.edited` / `session.idle`
console.warn audit rather than shelling out to grep.

### Phase 6: Diff Review

Use the package's `git-summary` tool (branch, status, recent commits, diff stats) or:

```bash
git diff --stat
git diff HEAD~1 --name-only
```

Review each changed file for:
- Unintended changes
- Missing error handling
- Potential edge cases

## Output Format

After running all phases, produce a verification report:

```
VERIFICATION REPORT
==================

Build:     [PASS/FAIL]
Types:     [PASS/FAIL] (X errors)
Lint:      [PASS/FAIL] (X warnings)
Tests:     [PASS/FAIL] (X/Y passed, Z% coverage)
Security:  [PASS/FAIL] (X issues)
Diff:      [X files changed]

Overall:   [READY/NOT READY] for PR

Issues to Fix:
1. ...
2. ...
```

## Continuous Mode

For long sessions, run verification every 15 minutes or after major changes:

```markdown
Set a mental checkpoint:
- After completing each function
- After finishing a component
- Before moving to next task

Run the verification checks defined in this skill.
```

## Integration with the Plugin

This skill complements the package plugin's edit hooks (`file.edited` formatting and
console.log warnings, `tool.execute.after` TypeScript checks) but provides deeper
verification. Hooks catch issues immediately; this skill provides comprehensive review.