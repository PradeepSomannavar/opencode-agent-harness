# Skills Index

The harness ships 15 skills. All are loaded on demand from `./skills` — a session
starts with only `AGENTS.md` and `INSTRUCTIONS.md` always injected, so the fixed
context footprint stays small regardless of how many skills the package contains.

## AI systems

| Skill | Purpose |
|-------|---------|
| `ai-architecture` | System architecture for AI/ML/GenAI systems. Apply when designing, reviewing, or refactoring LLM-based features, RAG systems, or agentic AI. |
| `mle-workflow` | Production machine-learning engineering workflow for data contracts, reproducible training, model evaluation, deployment, monitoring, and rollback. |

## Evaluation

| Skill | Purpose |
|-------|---------|
| `agent-evaluation` | Evaluation methodology for agentic AI systems. Covers tool-using agents, multi-agent systems, and autonomous loops. |
| `eval-harness` | Formal evaluation framework for OpenCode agent workflows implementing eval-driven development (EDD) principles. |
| `agent-self-evaluation` | Post-task self-rating on 5 axes (accuracy, completeness, clarity, actionability, conciseness) with a structured 1-5 scorecard. |

## Security

| Skill | Purpose |
|-------|---------|
| `ai-security` | Security considerations specific to AI/ML/LLM systems. Goes beyond traditional application security. |

## Prompting and MCP

| Skill | Purpose |
|-------|---------|
| `prompt-engineering` | Systematic prompt design, testing, and maintenance. |
| `mcp-development` | MCP (Model Context Protocol) server and tool development. |

## Observability and cost

| Skill | Purpose |
|-------|---------|
| `llm-observability` | Logging, tracing, and monitoring for LLM-based systems. |
| `cost-latency-optimization` | Optimization strategies for LLM-based systems — performance or cost. |
| `context-budget` | Audits context window consumption across agents, skills, MCP servers, and instructions; produces prioritized token-savings recommendations. |
| `strategic-compact` | Suggests manual context compaction at logical task boundaries rather than relying on arbitrary auto-compaction. |

## Verification and regression

| Skill | Purpose |
|-------|---------|
| `verification-loop` | A comprehensive verification system for OpenCode sessions before work is claimed complete. |
| `ai-regression-testing` | Regression testing strategies for AI-assisted development, sandbox-mode API testing, and catching AI blind spots. |
| `agent-introspection-debugging` | Structured self-debugging workflow for AI agent failures using capture, diagnosis, contained recovery, and introspection reports. |

## Skill file layout (for contributors)

Each skill is a directory `<name>` under `skills/` with a `SKILL.md` (frontmatter
`name` + `description`, then instructions). Skills register automatically via
`skills.paths`. To add a skill: create the directory and `SKILL.md`, then run
`npm run verify`.