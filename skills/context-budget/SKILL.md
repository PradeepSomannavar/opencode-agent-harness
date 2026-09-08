---
name: context-budget
description: Audits OpenCode context window consumption across agents, skills, MCP servers, and instructions. Identifies bloat, redundant components, and produces prioritized token-savings recommendations. Use when the context window is filling up too fast and the agents, skills, MCP servers, or instructions consuming it need to be identified.
metadata:
  origin: ECC
---

# Context Budget

Analyze token overhead across every loaded component in an OpenCode session and surface actionable optimizations to reclaim context space.

## When to Use

- Session performance feels sluggish or output quality is degrading
- You've recently added many skills, agents, or MCP servers
- You want to know how much context headroom you actually have
- Planning to add more components and need to know if there's room

Activate this skill on demand; the OpenCode skills system keeps it out of the baseline context until it is needed.

## How It Works

### Phase 1: Inventory

Scan all component directories and estimate token consumption:

**Agents** (`agents/*.txt` + `agent` entries in `opencode.json`)
- Count lines and tokens per prompt file (words × 1.3)
- Extract `description` length from the config's `agent` entries
- Flag: prompt files >200 lines (heavy), description >30 words (bloated)

**Skills** (`skills/*/SKILL.md`)
- Count tokens per SKILL.md
- Flag: files >400 lines
- Check for duplicate coverage between skills — skip near-identical copies to avoid double-counting

**Instructions** (`AGENTS.md`, `INSTRUCTIONS.md` — always injected)
- Count tokens per file
- Flag: combined total >300 lines, or content that duplicates what a skill covers

**MCP Servers** (configured via `mcp` in the OpenCode config)
- Count configured servers and total tool count
- Estimate schema overhead at ~500 tokens per tool
- Flag: servers with >20 tools, servers that wrap simple CLI commands (`gh`, `git`, `npm`, `supabase`, `vercel`)

### Phase 2: Classify

Sort every component into a bucket:

| Bucket | Criteria | Action |
|--------|----------|--------|
| **Always needed** | Referenced in AGENTS.md/INSTRUCTIONS.md, backs an active command, or matches current project type | Keep |
| **Sometimes needed** | Domain-specific (e.g. language patterns), not referenced in the always-injected instructions | Consider on-demand activation |
| **Rarely needed** | No command/instruction reference, overlapping content, or no obvious project match | Remove or lazy-load |

### Phase 3: Detect Issues

Identify the following problem patterns:

- **Bloated agent descriptions** — description >30 words in the config loads into every Task invocation
- **Heavy agents** — prompt files >200 lines inflate subagent context on every spawn
- **Redundant components** — skills that duplicate agent logic, instructions that duplicate skills
- **MCP over-subscription** — >10 servers, or servers wrapping CLI tools available for free
- **Instructions bloat** — verbose explanations, outdated sections, content that should move into an on-demand skill

### Phase 4: Report

Produce the context budget report:

```
Context Budget Report
═══════════════════════════════════════

Total estimated overhead: ~XX,XXX tokens
Context model: <current model context window>
Effective available context: ~XXX,XXX tokens (XX%)

Component Breakdown:
┌─────────────────┬────────┬───────────┐
│ Component       │ Count  │ Tokens    │
├─────────────────┼────────┼───────────┤
│ Agents          │ N      │ ~X,XXX    │
│ Skills          │ N      │ ~X,XXX    │
│ Instructions    │ N      │ ~X,XXX    │
│ MCP tools       │ N      │ ~XX,XXX   │
└─────────────────┴────────┴───────────┘

WARNING: Issues Found (N):
[ranked by token savings]

Top 3 Optimizations:
1. [action] → save ~X,XXX tokens
2. [action] → save ~X,XXX tokens
3. [action] → save ~X,XXX tokens

Potential savings: ~XX,XXX tokens (XX% of current overhead)
```

In verbose mode, additionally output per-file token counts, line-by-line breakdown of the heaviest files, specific redundant lines between overlapping components, and MCP tool list with per-tool schema size estimates.

## Examples

**Basic audit**
```
User: Audit my context usage
Skill: Scans setup → 7 agents (12,400 tokens), 15 skills (6,200), 87 MCP tools (43,500),
       2 instruction files (1,200)
       Flags: 3 heavy agents, 14 MCP servers (3 CLI-replaceable)
       Top saving: remove 3 MCP servers → -27,500 tokens (47% overhead reduction)
```

**Verbose mode**
```
User: Context budget, verbose
Skill: Full report + per-file breakdown showing <agent>.txt (213 lines, 1,840 tokens),
       MCP tool list with per-tool sizes, duplicated rule lines side by side
```

**Pre-expansion check**
```
User: I want to add 5 more MCP servers, do I have room?
Skill: Current overhead 33% → adding 5 servers (~50 tools) would add ~25,000 tokens → pushes to 45% overhead
       Recommendation: remove 2 CLI-replaceable servers first to stay under 40%
```

## Best Practices

- **Token estimation**: use `words × 1.3` for prose, `chars / 4` for code-heavy files
- **MCP is the biggest lever**: each tool schema costs ~500 tokens; a 30-tool server costs more than all your skills combined
- **Agent descriptions are loaded always**: even if the agent is never invoked, its description field is present in every Task context
- **Instructions are always injected**: keep AGENTS.md/INSTRUCTIONS.md lean; move detail into on-demand skills
- **Verbose mode for debugging**: use when you need to pinpoint the exact files driving overhead, not for regular audits
- **Audit after changes**: run after adding any agent, skill, or MCP server to catch creep early