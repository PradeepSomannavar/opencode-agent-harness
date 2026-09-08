---
name: cost-latency-optimization
description: Optimization strategies for LLM-based systems. Apply when performance or cost is a concern.
metadata:
  origin: AI-Engineering
---

# Cost and Latency Optimization Skill

Optimization strategies for LLM-based systems. Apply when performance or cost is a concern.

## Optimization Strategies

### Model Selection
| Strategy | Impact | When to Use |
|----------|--------|-------------|
| Use smaller model for simple tasks | 3-10x cost reduction | Classification, extraction |
| Route by complexity | Balanced cost/quality | Multi-tier systems |
| Use cached responses | Near-zero marginal cost | Repeated queries |
| Batch similar requests | Reduced API overhead | High-throughput systems |

### Token Optimization
| Strategy | Impact | When to Use |
|----------|--------|-------------|
| Compress context | Linear token reduction | Long documents |
| Selective retrieval | Reduced context tokens | RAG systems |
| Prompt deduplication | Reduced prompt tokens | Repeated patterns |
| Output format constraints | Reduced output tokens | Structured output |

### Caching
| Strategy | Impact | When to Use |
|----------|--------|-------------|
| Semantic caching | Skip LLM for similar queries | Repetitive patterns |
| Tool output caching | Avoid re-executing tools | Expensive operations |
| Embedding caching | Skip re-embedding | Document ingestion |
| Response caching | Exact match reuse | Deterministic queries |

### Latency Reduction
| Strategy | Impact | When to Use |
|----------|--------|-------------|
| Streaming responses | Perceived latency reduction | User-facing |
| Parallel tool calls | Wall-clock reduction | Independent operations |
| Pre-computation | Reduced per-request latency | Predictable queries |
| Model quantization | Faster inference | Self-hosted models |

## Cost Monitoring

Track these metrics continuously:
- Cost per request
- Cost per feature
- Cost per user
- Token usage distribution
- Cache hit rate
- Model fallback rate

## Optimization Decision Framework

1. Measure current cost and latency
2. Identify bottleneck (model, tokens, tools, retrieval)
3. Apply cheapest optimization first
4. Measure impact
5. Continue until budget met

## Anti-Patterns

- Optimizing before measuring
- Sacrificing quality for cost without metrics
- Caching without invalidation strategy
- Ignoring latency in user-facing features
- Not tracking cost per feature
