# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-09-08

### Added

- Initial public release of OpenCode Agent Harness.
- 7 OpenCode agents: `build` (primary) plus `ai-architect`,
  `rag-pipeline-reviewer`, `mle-reviewer`, `agent-evaluator`,
  `ai-security-reviewer`, and `code-architect` (read-only subagents).
- 4 commands: `/ai-review`, `/rag-review`, `/eval-run`, `/ai-security`.
- 15 on-demand skills for AI architecture, agent/LLM evaluation, AI security,
  prompt engineering, MCP development, LLM observability, cost/latency
  optimization, and verification/regression workflows.
- 8 tools: `run-tests`, `check-coverage`, `security-audit`, `format-code`,
  `lint-check`, `git-summary`, `changed-files`, `dependency-analyzer`.
- OpenCode plugin with hooks for shell-environment injection (`AIE_*`),
  session lifecycle handling, formatting/audit triggers, context compaction,
  and change tracking.
- Installers (`install.ps1`, `install.sh`) with backup + marker-based uninstall.
- Package self-check (`npm run verify`), TypeScript build, and CI workflow.

[1.0.0]: https://github.com/PradeepSomannavar/opencode-agent-harness/releases/tag/v1.0.0