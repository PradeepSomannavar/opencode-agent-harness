---
name: llm-observability
description: Logging, tracing, and monitoring for LLM-based systems. Apply when implementing or reviewing observability in AI features.
metadata:
  origin: AI-Engineering
---

# LLM Observability Skill

Logging, tracing, and monitoring for LLM-based systems. Apply when implementing or reviewing observability in AI features.

## Required Observability Data

### Per Request
- Request ID (UUID for tracing)
- Trace ID (distributed tracing)
- Model name and version
- Provider name
- Prompt version/hash
- Input token count
- Output token count
- Total tokens
- Estimated cost (USD)
- Latency (total, time-to-first-token)
- Tool calls made
- Tool errors
- Agent steps taken
- Termination reason

### Per Session
- Session ID
- Model/provider used
- Total tokens consumed
- Total cost
- Number of requests
- Average latency
- Error rate
- Evaluation scores

### Per Agent Step
- Step number
- Tool selected
- Tool input summary
- Tool output summary
- Tokens consumed
- Duration
- Decision rationale

## Logging Best Practices

```
Log structured JSON, not free text.
Include request_id in every log entry.
Never log secrets or PII.
Use log levels appropriately.
Implement log rotation and retention.
```

## Monitoring Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| Error rate | Failed LLM calls / total | > 5% |
| P95 latency | 95th percentile response time | > context-dependent |
| Token usage | Average tokens per request | Increasing trend |
| Cost per request | Average USD per request | Above budget |
| Hallucination rate | Generated content not grounded | > baseline |
| Tool error rate | Failed tool calls / total | > 10% |

## Cost Visibility

Track and report:
- Cost per model/provider
- Cost per feature/use-case
- Cost per user (if applicable)
- Cost trends over time
- Cost vs quality tradeoffs

## Anti-Patterns

- Logging secrets or API keys
- No structured logging
- Not tracking token usage
- No latency measurement
- No cost visibility
- Storing PII in logs
- No alerting on error rates
