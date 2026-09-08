# Agents Reference

The harness defines 7 agents. One primary agent runs the session; six read-only
subagents provide specialized review output on demand.

## `build` (primary)

Default coding agent for implementation work.

- Mode: primary
- Tools: `write`, `edit`, `bash`, `read`, `changed-files`

## `ai-architect` (subagent)

AI systems architect specializing in LLM-based systems, RAG pipelines, agentic AI,
and GenAI application design. Use for AI feature architecture, model selection,
system design, and failure mode analysis.

- Read + bash only (no write/edit on project files)
- Invoked by: `/ai-review`

## `rag-pipeline-reviewer` (subagent)

Reviews RAG (Retrieval-Augmented Generation) pipelines for retrieval quality,
chunking strategy, embedding choices, and evaluation coverage. Invoke when building,
modifying, or debugging a RAG system, vector store integration, or questions about
retrieval accuracy.

- Read + bash only
- Invoked by: `/rag-review`

## `mle-reviewer` (subagent)

Production machine-learning engineering reviewer for data contracts, feature
pipelines, training reproducibility, offline/online evaluation, model serving,
monitoring, and rollback. Use when ML, MLOps, model training, inference, feature
store, or evaluation code changes.

- Read + bash only

## `agent-evaluator` (subagent)

Evaluates agent output against a 5-axis quality rubric: accuracy, completeness,
clarity, actionability, conciseness. Produces a structured scorecard with evidence
per criterion and concrete improvement suggestions.

- Read + bash only
- Invoked by: `/eval-run`

## `ai-security-reviewer` (subagent)

AI security specialist for prompt injection, tool abuse, MCP security, and agent
privilege escalation. Use when reviewing AI features for security vulnerabilities.

- Read + bash only
- Invoked by: `/ai-security`

## `code-architect` (subagent)

Designs feature architectures by analyzing existing codebase patterns and
conventions, then provides implementation blueprints with concrete files,
interfaces, data flow, and build order.

- Read + bash only

## Agent file layout (for contributors)

Each subagent is defined in `opencode.json` and its system prompt lives in
`agents/<name>.txt`. To add an agent: create `agents/<name>.txt`, register the
entry under `agent` in `opencode.json`, optionally bind it to a command, then run
`npm run verify`.