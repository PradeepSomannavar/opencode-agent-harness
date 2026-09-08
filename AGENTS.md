# OpenCode Agent Harness — Agent Instructions

This package provides a focused set of **AI-engineering review agents**, skills, commands, hooks, and tools for OpenCode.

Version: 1.0.0

## Context Policy

- `AGENTS.md` and `INSTRUCTIONS.md` are always injected.
- ALL skills load on-demand only (never preload every `SKILL.md`).

## Available Agents

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| build | Primary coding agent for development work | Default coding, implementation |
| ai-architect | AI systems architecture, model selection, failure modes | LLM features, RAG, agentic AI design |
| rag-pipeline-reviewer | RAG retrieval quality, chunking, reranking, eval coverage | RAG pipelines, vector stores, retrieval accuracy |
| mle-reviewer | Production ML engineering review | ML pipelines, evals, serving, monitoring, rollback |
| agent-evaluator | 5-axis LLM/agent output evaluation | Quality assessment of model or agent output |
| ai-security-reviewer | Prompt injection, tool abuse, MCP security | AI feature security review |
| code-architect | Feature architecture blueprints from codebase patterns | Feature construction planning |

## Agent Orchestration

- Complex or security-sensitive AI work → delegate to the matching review agent.
- Run review agents with **read-only** tooling; the primary `build` agent implements.
- Send the review result back to the user as a concise summary — review agent output is not user-visible.
- Review agents small enough to not need delegation → still delegate for consistency (they encode domain expertise).

## Skills (on-demand)

All skills live under `skills/` and load via the skills system. Call the relevant skill when a task matches its description. The set covers: AI systems architecture, RAG, security, MLE, evaluation, observability, prompt engineering, MCP development, cost/latency optimization, plus workflow skills (evaluation harness, regression testing, introspection debugging, verification loop, context budget, strategic compaction, self-evaluation).

## Defaults

- Prefer typed, immutable, small files; follow existing repo conventions.
- Validate all inputs; never hardcode secrets.
- Run tests and the verification loop before declaring work complete.
- Report work concisely; use the package's tools (`run-tests`, `lint-check`, `git-summary`, `changed-files`, `check-coverage`, `security-audit`, `format-code`, `dependency-analyzer`) for the matching job.