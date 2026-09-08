---
name: ai-architecture
description: System architecture for AI/ML/GenAI systems. Apply when designing, reviewing, or refactoring LLM-based features, RAG systems, or agentic AI.
metadata:
  origin: AI-Engineering
---

# AI Architecture Skill

System architecture for AI/ML/GenAI systems. Apply when designing, reviewing, or refactoring LLM-based features, RAG systems, or agentic AI.

## Architecture Review Checklist

For every AI system, evaluate:

### Requirements
- [ ] Explicit goal and acceptance criteria defined
- [ ] Failure modes identified and bounded
- [ ] Evaluation criteria specified before implementation
- [ ] Cost and latency budgets established

### Components
- [ ] Model selection justified (provider, version, capabilities)
- [ ] Prompt/version tracked and reproducible
- [ ] Tool boundaries explicit (what tools agents can access)
- [ ] Memory/persistence strategy defined
- [ ] Retrieval pipeline specified (if RAG)

### Safety
- [ ] Agent execution bounded (timeouts, loop limits)
- [ ] Tool inputs/outputs validated
- [ ] Secrets never exposed to model
- [ ] Human escalation path defined
- [ ] Data exfiltration risks assessed

### Observability
- [ ] Request/trace IDs for tracing
- [ ] Model, provider, version tracked
- [ ] Token usage and cost logged
- [ ] Tool calls and errors recorded
- [ ] Evaluation scores captured

### Scalability
- [ ] Context window limits considered
- [ ] Caching strategy defined
- [ ] Fallback models configured
- [ ] Rate limiting in place
- [ ] Cost optimization strategy documented

## Failure Mode Analysis

For each component, document:

```
Component: [name]
Failure mode: [what can go wrong]
Detection: [how to detect it]
Mitigation: [how to handle it]
Fallback: [what happens if it fails]
```

## Model Selection Framework

| Capability | Model Class | When to Use |
|-----------|------------|-------------|
| Simple classification | Small/Haiku-class | High volume, low latency |
| Code generation | Medium/Sonnet-class | Primary development |
| Complex reasoning | Large/Opus-class | Architecture, research |

Always consider: cost per token, latency, context window, capability requirements.
