---
name: agent-evaluation
description: Evaluation methodology for agentic AI systems. Covers tool-using agents, multi-agent systems, and autonomous loops.
metadata:
  origin: AI-Engineering
---

# Agent Evaluation Skill

Evaluation methodology for agentic AI systems. Covers tool-using agents, multi-agent systems, and autonomous loops.

## Agent Evaluation Dimensions

### Task Completion
- Did the agent complete the assigned task?
- Was the output correct and complete?
- How many attempts were needed?

### Planning Quality
- Did the agent create a plan before acting?
- Was the plan reasonable and efficient?
- Did the agent adapt the plan when needed?

### Tool Usage
- Were the right tools selected?
- Were tool arguments correct?
- Were tool results properly handled?
- Did the agent avoid unnecessary tool calls?

### Termination
- Did the agent terminate properly?
- Did it avoid infinite loops?
- Was the termination condition appropriate?

### Safety
- Did the agent respect tool boundaries?
- Were permissions respected?
- Was sensitive data protected?
- Did the agent escalate when uncertain?

### Efficiency
- Total tokens used
- Total cost
- Wall-clock time
- Number of tool calls
- Context window utilization

## Agent Evaluation Checklist

```
Before evaluation:
- [ ] Evaluation criteria defined
- [ ] Test scenarios prepared
- [ ] Success/failure criteria documented
- [ ] Cost tracking enabled
- [ ] Latency measurement enabled

During evaluation:
- [ ] All tool calls logged
- [ ] Token usage tracked
- [ ] Decision points recorded
- [ ] Error handling observed

After evaluation:
- [ ] Task completion assessed
- [ ] Planning quality reviewed
- [ ] Tool usage analyzed
- [ ] Cost and latency computed
- [ ] Regression compared to baseline
```

## Multi-Agent Evaluation

For multi-agent systems, additionally evaluate:
- Communication quality between agents
- Task delegation appropriateness
- Conflict resolution
- Orchestration overhead

## Agent Evaluation Anti-Patterns

- Evaluating only final output (ignore the process)
- Not tracking cost and latency
- Testing only happy path scenarios
- Ignoring tool misuse patterns
- Not comparing against baseline
- Evaluating without reproducible seeds where possible
