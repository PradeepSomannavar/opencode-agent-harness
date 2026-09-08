# Examples

Each example is a realistic prompt you can paste into OpenCode after the harness is
installed. Parameters in `<angle brackets>` are placeholders.

## 1. Review an LLM feature architecture

```text
/ai-review We are adding a streaming chat endpoint to an existing LLM feature.

Assess:
1. Architecture and data flow (client, gateway, LLM provider, persistence).
2. Failure modes: timeouts, partial streams, upstream retries, idempotency.
3. Retrieval quality if we add a RAG path.
4. What to verify before merge and how.
Be concrete: name files, interfaces, and acceptance checks.
```

## 2. Review a RAG pipeline

```text
/rag-review Our ingestion chunked fixed 500-token windows and we top-k=10 retrieve
from an embeddings index, no reranking.

Give concrete recommendations on:
- chunking strategy and overlap
- embedding choice and indexing
- top-k, similarity threshold, and reranking
- grounding/hallucination risks and evaluation coverage (which metrics, which set)
```

## 3. Evaluate an agent run

```text
/eval-run Evaluate the last agent run that added retry logic to an httpx client.
The output claimed tests pass but did not cite test output and left TODOs.

Score on: accuracy, completeness, clarity, actionability, conciseness.
For each axis: evidence, score 1-5, and the single most useful improvement.
```

## 4. Run an AI security review

```text
/ai-security Review the new chat endpoint and its tool definitions for:
- prompt injection (system boundary, tool outputs, stored content)
- tool abuse and agent privilege escalation
- MCP server integration risks, if any
Report severities, exploit sketches (no real exploits), and fixes.
```

## Notes

- Every example is read-only: the review agents cannot write or edit project files.
- Run `npm run verify` after any change to the package to confirm agents, commands,
  and skills still resolve.