# Commands Reference

The harness ships 4 commands. Each command is a `subtask` — it runs its template
plus your arguments through the named review agent without taking over the main
session.

| Command | Agent | Template |
|---------|-------|----------|
| `/ai-review` | `ai-architect` | `commands/ai-review.md` |
| `/rag-review` | `rag-pipeline-reviewer` | `commands/rag-review.md` |
| `/eval-run` | `agent-evaluator` | `commands/eval-run.md` |
| `/ai-security` | `ai-security-reviewer` | `commands/ai-security.md` |

## `/ai-review`

Review AI system architecture, RAG pipeline, or LLM feature design.

```text
/ai-review Review the architecture for the new streaming chat endpoint. Focus on
failure modes and retrieval quality.
```

## `/rag-review`

Review and optimize a RAG pipeline: ingestion, chunking, retrieval, generation.

```text
/rag-review Assess our chunking strategy and top-k retrieval. We suspect irrelevant
top results are hurting answer quality.
```

## `/eval-run`

Run an LLM or agent evaluation against an evaluation dataset.

```text
/eval-run Evaluate the last agent output for the retry-logic fix. It claimed tests
pass but did not cite test output.
```

## `/ai-security`

Run an AI security review: prompt injection, tool abuse, MCP security.

```text
/ai-security Review the new chat endpoint and its tool definitions for prompt
injection and tool abuse risks.
```

## Command file layout (for contributors)

Command templates live in `commands/<name>.md` and are referenced from
`opencode.json` under `command` with `agent` + `subtask: true`. To add a command:
create the template, register the entry, then run `npm run verify`.