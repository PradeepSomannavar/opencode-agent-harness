---
name: strategic-compact
description: Suggests manual context compaction at logical task boundaries rather than relying on arbitrary auto-compaction. Use when a session is approaching a context limit and a task phase is a natural place to compact.
metadata:
  origin: ECC
---

# Strategic Compact Skill

Suggests manual context compaction at strategic points in your workflow rather than relying on arbitrary auto-compaction.

## When to Activate

- Running long sessions that approach context limits (200K+ tokens)
- Working on multi-phase tasks (research → plan → implement → test)
- Switching between unrelated tasks within the same session
- After completing a major milestone and starting new work
- When responses slow down or become less coherent (context pressure)

## Why Strategic Compaction?

Auto-compaction triggers at arbitrary points:
- Often mid-task, losing important context
- No awareness of logical task boundaries
- Can interrupt complex multi-step operations

Strategic compaction at logical boundaries:
- **After exploration, before execution** — Compact research context, keep implementation plan
- **After completing a milestone** — Fresh start for next phase
- **Before major context shifts** — Clear exploration context before different task

## How It Works

This package ships no background suggestion script. Instead:

1. **Watch context-pressure signals** — responses slow down, output quality degrades, or the session reports it is approaching the model's context limit.
2. **Know your window** — check the active model's context-window size; the "effective headroom" is roughly window minus key instructions minus current conversation.
3. **Use the plugin's compaction block** — this package's plugin (`plugins/aie-hooks.ts`) registers an `experimental.session.compacting` hook. When compaction runs, it injects a salvage block that preserves: the active plugin, hooks, tools, agents, the package's key principles, and recently edited files, plus a compaction prompt telling the summarizer what to keep and what to discard.
4. **Compact at a task phase, then continue** — request compaction at the boundary, optionally attaching a short note describing what the next phase needs.

## What Survives Compaction

Understanding what persists helps you compact with confidence:

| Persists | Lost |
|----------|------|
| Project instructions (AGENTS.md, INSTRUCTIONS.md) | Intermediate reasoning and analysis |
| Files on disk | File contents you previously read |
| Notes written to project files before compacting | Multi-step conversation context |
| Git state (commits, branches) | Tool call history and counts |
| The session's todo list (if the harness preserves it) | Nuanced user preferences stated verbally |

> ### Write the plan to a file before compacting
>
> A task list may or may not survive compaction depending on the harness; a file on
> disk always persists. **Write important context to a file before compacting** and
> treat any in-memory todo list as a convenience, never as your durable record.

## Compaction Decision Guide

Use this table to decide when to compact:

| Phase Transition | Compact? | Why |
|-----------------|----------|-----|
| Research → Planning | Yes | Research context is bulky; plan is the distilled output |
| Planning → Implementation | Yes | Plan is written down (a file, or the task list if you have one); free up context for code |
| Implementation → Testing | Maybe | Keep if tests reference recent code; compact if switching focus |
| Debugging → Next feature | Yes | Debug traces pollute context for unrelated work |
| Mid-implementation | No | Losing variable names, file paths, and partial state is costly |
| After a failed approach | Yes | Clear the dead-end reasoning before trying a new approach |

## Best Practices

1. **Compact after planning** — Once the plan is finalized **and written to a file**, compact to start fresh
2. **Compact after debugging** — Clear error-resolution context before continuing
3. **Don't compact mid-implementation** — Preserve context for related changes
4. **Attach a summary when compacting** — Many harnesses accept a short note: "Compact focusing on implementing next: auth middleware"
5. **Write before compacting** — Save important context to files before compacting
6. **Re-verify after compacting** — After compaction, confirm the plan and recent decisions survived; re-read key files if needed

## Token Optimization Patterns

### Trigger-Table Lazy Loading
Skills in this package are already loaded on-demand (never preloaded at session start),
which keeps baseline context low. When reviewing your own setup, prefer the same pattern:
load domain guidance only when its trigger appears:

| Trigger | Skill (on-demand) | Load When |
|---------|--------------------|-----------|
| "test", "tdd", "coverage" | `verification-loop` | User mentions testing |
| "security", "auth", "xss" | `ai-security` | Security-related work |
| "eval", "benchmark" | `agent-evaluation` | Evaluation context |

### Context Composition Awareness
Monitor what's consuming your context window:
- **Always-injected instructions** — AGENTS.md / INSTRUCTIONS.md, keep lean
- **Loaded skills** — Each skill adds 1-5K tokens
- **Conversation history** — Grows with each exchange
- **Tool results** — File reads, search results add bulk
- **MCP servers** — Each tool schema adds overhead; prune servers with large schemas

### Duplicate Instruction Detection
Common sources of duplicate context:
- Same rules in both user-level and project-level config
- Skills that repeat always-injected instructions
- Multiple skills covering overlapping domains

### Context Optimization Tools
- Keep skills on-demand (this package already does)
- Prune MCP servers whose tool schemas you rarely use
- Keep always-injected instructions short; move detail into skills that load on demand

## Related

- Session compaction context block — provided by this package's `experimental.session.compacting` hook
- Save durable learnings in the project's own documentation before ending the session