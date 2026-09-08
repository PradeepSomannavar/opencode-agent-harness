#!/usr/bin/env bash
set -euo pipefail

# Install or uninstall the opencode-agent-harness package into an OpenCode config dir.
#
# OpenCode loads local plugins from <config-dir>/plugins/ (with their sibling runtime
# files resolving from the config dir) and discovers skills in
# <config-dir>/skills/<name>/SKILL.md, so this installer:
#   - copies package content into a managed subdir: <target>/opencode-agent-harness/
#   - stages the runtime spine into the config dir beneath the convention directories:
#     plugins/ and tools/ (the plugin imports ../tools/*, so tools must sit at the
#     same level as plugins), plus skills/<name>/ (existing files/dirs are skipped,
#     never overwritten)
#   - merges agent/command/instructions entries into opencode.json (absolute file refs
#     into the managed subdir; pre-existing keys are SKIPPED and recorded)
#   - leaves default_agent and everything else in the config untouched
#
# A marker (.opencode-agent-harness.marker) records every change for exact reversal.
#
# Usage:
#   install/install.sh                 # default target: $HOME/.config/opencode
#   install/install.sh --target PATH
#   install/install.sh --uninstall

PKG="opencode-agent-harness"
PKG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
MODE="install"

while [ $# -gt 0 ]; do
  case "$1" in
    --uninstall) MODE="uninstall"; shift ;;
    --target) TARGET="$2"; shift 2 ;;
    --target=*) TARGET="${1#*=}"; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

ts() { date "+%Y-%m-%d %H:%M:%S"; }
say() { printf "[%s] %s\n" "$(ts)" "$1"; }

if [ -z "$TARGET" ]; then
  TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required (used to merge config and write the marker). Install it and retry, e.g.:" >&2
  echo "  Debian/Ubuntu: sudo apt-get install jq" >&2
  echo "  macOS:         brew install jq" >&2
  echo "  Windows:       winget install jq" >&2
  exit 3
fi

MANAGED="$TARGET/$PKG"
MARKER="$TARGET/.$PKG.marker"

AGENT_KEYS=(ai-architect rag-pipeline-reviewer mle-reviewer agent-evaluator ai-security-reviewer code-architect)
COMMAND_KEYS=(ai-review rag-review eval-run ai-security)

agent_desc() {
  case "$1" in
    ai-architect) echo "AI systems architect specializing in LLM-based systems, RAG pipelines, agentic AI, and GenAI application design. Use for AI feature architecture, model selection, system design, and failure mode analysis." ;;
    rag-pipeline-reviewer) echo "Reviews RAG (Retrieval-Augmented Generation) pipelines for retrieval quality, chunking strategy, embedding choices, and evaluation coverage. Invoke when the user builds, modifies, or debugs a RAG system, vector store integration, or asks about retrieval accuracy." ;;
    mle-reviewer) echo "Production machine-learning engineering reviewer for data contracts, feature pipelines, training reproducibility, offline/online evaluation, model serving, monitoring, and rollback. Use when ML, MLOps, model training, inference, feature store, or evaluation code changes." ;;
    agent-evaluator) echo "Evaluates agent output against a 5-axis quality rubric (accuracy, completeness, clarity, actionability, conciseness). Use after a non-trivial task when the user wants a quality assessment. Produces a structured scorecard with evidence and suggested improvements." ;;
    ai-security-reviewer) echo "AI security specialist for prompt injection, tool abuse, MCP security, and agent privilege escalation. Use when reviewing AI features for security vulnerabilities." ;;
    code-architect) echo "Designs feature architectures by analyzing existing codebase patterns and conventions, then providing implementation blueprints with concrete files, interfaces, data flow, and build order." ;;
    *) echo "" ;;
  esac
}

cmd_args() {
  case "$1" in
    ai-review)   echo "Review AI system architecture, RAG pipeline, or LLM feature design|ai-architect" ;;
    rag-review)  echo "Review and optimize RAG pipeline (ingestion, chunking, retrieval, generation)|rag-pipeline-reviewer" ;;
    eval-run)    echo "Run LLM or agent evaluation against evaluation dataset|agent-evaluator" ;;
    ai-security) echo "Run AI security review (prompt injection, tool abuse, MCP security)|ai-security-reviewer" ;;
    *) echo "||" ;;
  esac
}

if [ "$MODE" = "uninstall" ]; then
  if [ ! -f "$MARKER" ]; then echo "No marker at $MARKER - nothing to uninstall." >&2; exit 1; fi

  CFG_PATH="$(jq -r '.configPath' "$MARKER")"
  BACKUP_PATH="$(jq -r '.backupPath' "$MARKER")"
  MANAGED_MARKED="$(jq -r '.managedPath' "$MARKER")"
  CREATED_CFG="$(jq -r '.createdConfig // false' "$MARKER")"

  if [ -n "$CFG_PATH" ] && [ -f "$CFG_PATH" ] && command -v jq >/dev/null 2>&1; then
    jq --argjson agents "$(jq '.addedAgentKeys' "$MARKER")" \
       --argjson cmds  "$(jq '.addedCommandKeys' "$MARKER")" \
       --argjson ins   "$(jq '.addedInstructions' "$MARKER")" '
         . as $root
         | .agent   = (($root.agent // {}) | with_entries(select(.key != ($agents[]))))
         | .command = (($root.command // {}) | with_entries(select(.key != ($cmds[]))))
         | .instructions = (($root.instructions // []) | map(select(. as $i | $ins | index($i) | not)))
       ' "$CFG_PATH" > "$CFG_PATH.tmp" && mv "$CFG_PATH.tmp" "$CFG_PATH"
    say "Reversed config changes in $CFG_PATH"
  fi

  # remove staged plugin files, tool files, and skill dirs (only the entries recorded
  # in the marker); strip trailing CR because Windows jq emits CRLF
  strip_cr() { sed 's/\r$//'; }

  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    if [ -f "$TARGET/$rel" ]; then
      rm -f "$TARGET/$rel"
      say "Removed staged plugin file $rel"
    fi
  done < <(jq -r '.stagedPluginFiles[]?' "$MARKER" | strip_cr)

  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    if [ -f "$TARGET/$rel" ]; then
      rm -f "$TARGET/$rel"
      say "Removed staged tool file $rel"
    fi
  done < <(jq -r '.stagedToolFiles[]?' "$MARKER" | strip_cr)

  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    if [ -d "$TARGET/$rel" ]; then
      rm -rf "$TARGET/$rel"
      say "Removed staged skill dir $rel"
    fi
  done < <(jq -r '.stagedSkillDirs[]?' "$MARKER" | strip_cr)

  # prune only the directories that are now EMPTY (anything the user pre-existed
  # on is left untouched)
  while IFS= read -r rel; do
    [ -z "$rel" ] && continue
    d="$(dirname "$rel")"
    while [ "$d" != "." ] && [ "$d" != "/" ] && [ -n "$d" ]; do
      rmdir "$TARGET/$d" 2>/dev/null && say "Removed empty staged dir $d"
      d="$(dirname "$d")"
    done
  done < <({ jq -r '.stagedPluginFiles[]?' "$MARKER"; jq -r '.stagedToolFiles[]?' "$MARKER"; } | strip_cr)

  for d in plugins tools skills; do
    rmdir "$TARGET/$d" 2>/dev/null && say "Removed empty staged dir $d"
  done

  if [ -n "$BACKUP_PATH" ] && [ -f "$BACKUP_PATH" ]; then
    cp -f "$BACKUP_PATH" "$CFG_PATH"
    say "Restored config backup into $CFG_PATH"
  elif [ "$CREATED_CFG" = "true" ] && [ -n "$CFG_PATH" ] && [ -f "$CFG_PATH" ]; then
    rm -f "$CFG_PATH"
    say "Removed config file created by install: $CFG_PATH"
  fi
  if [ -n "$MANAGED_MARKED" ] && [ -d "$MANAGED_MARKED" ]; then rm -rf "$MANAGED_MARKED"; fi
  rm -f "$MARKER"
  say "Uninstall complete."
  exit 0
fi

if [ -e "$MARKER" ]; then
  echo "$PKG appears already installed ($MARKER exists). Run with --uninstall first." >&2; exit 1
fi
if [ -e "$MANAGED" ]; then
  echo "$MANAGED already exists but no marker was found; remove it manually if stale." >&2; exit 1
fi

mkdir -p "$MANAGED" "$TARGET"
for d in agents commands skills plugins tools tests install docs examples; do
  [ -d "$PKG_ROOT/$d" ] && cp -R "$PKG_ROOT/$d" "$MANAGED/"
done
for f in AGENTS.md INSTRUCTIONS.md index.ts package.json tsconfig.json README.md LICENSE opencode.json; do
  [ -f "$PKG_ROOT/$f" ] && cp "$PKG_ROOT/$f" "$MANAGED/"
done
say "Copied package into $MANAGED"

# stage plugin + skills into the OpenCode convention directories
STAGED_PLUGIN_FILES='[]'; SKIPPED_PLUGIN_FILES='[]'
if [ -d "$PKG_ROOT/plugins" ]; then
  mkdir -p "$TARGET/plugins"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    rel="${f#"$PKG_ROOT/plugins/"}"
    if [ -e "$TARGET/plugins/$rel" ]; then
      SKIPPED_PLUGIN_FILES="$(printf '%s\n%s' "$SKIPPED_PLUGIN_FILES" "$(jq -n --arg r "plugins/$rel" '[$r]')" | jq -s 'add')"
    else
      mkdir -p "$(dirname "$TARGET/plugins/$rel")"
      cp "$f" "$TARGET/plugins/$rel"
      STAGED_PLUGIN_FILES="$(printf '%s\n%s' "$STAGED_PLUGIN_FILES" "$(jq -n --arg r "plugins/$rel" '[$r]')" | jq -s 'add')"
    fi
  done < <(find "$PKG_ROOT/plugins" -type f)
fi

STAGED_SKILL_DIRS='[]'; SKIPPED_SKILL_DIRS='[]'
if [ -d "$PKG_ROOT/skills" ]; then
  mkdir -p "$TARGET/skills"
  for d in "$PKG_ROOT"/skills/*/; do
    d="${d%/}"
    [ -d "$d" ] || continue
    name="${d##*/}"
    if [ -e "$TARGET/skills/$name" ]; then
      SKIPPED_SKILL_DIRS="$(printf '%s\n%s' "$SKIPPED_SKILL_DIRS" "$(jq -n --arg r "skills/$name" '[$r]')" | jq -s 'add')"
    else
      cp -R "$d" "$TARGET/skills/$name"
      STAGED_SKILL_DIRS="$(printf '%s\n%s' "$STAGED_SKILL_DIRS" "$(jq -n --arg r "skills/$name" '[$r]')" | jq -s 'add')"
    fi
  done
fi

if [ "$STAGED_PLUGIN_FILES" != "[]" ]; then say "Staged plugin files into $TARGET/plugins"; fi
if [ "$STAGED_SKILL_DIRS" != "[]" ]; then say "Staged skill dirs into $TARGET/skills"; fi

# tools/ is a sibling of plugins/ in the package; the plugin imports "../tools/*",
# so tools must live at the SAME level (the config dir) for the plugin to load.
STAGED_TOOL_FILES='[]'; SKIPPED_TOOL_FILES='[]'
if [ -d "$PKG_ROOT/tools" ]; then
  mkdir -p "$TARGET/tools"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    rel="${f#"$PKG_ROOT/tools/"}"
    if [ -e "$TARGET/tools/$rel" ]; then
      SKIPPED_TOOL_FILES="$(printf '%s\n%s' "$SKIPPED_TOOL_FILES" "$(jq -n --arg r "tools/$rel" '[$r]')" | jq -s 'add')"
    else
      mkdir -p "$(dirname "$TARGET/tools/$rel")"
      cp "$f" "$TARGET/tools/$rel"
      STAGED_TOOL_FILES="$(printf '%s\n%s' "$STAGED_TOOL_FILES" "$(jq -n --arg r "tools/$rel" '[$r]')" | jq -s 'add')"
    fi
  done < <(find "$PKG_ROOT/tools" -type f)
fi

if [ "$STAGED_TOOL_FILES" != "[]" ]; then say "Staged tool files into $TARGET/tools"; fi

CFG_PATH=""
if [ -f "$TARGET/opencode.jsonc" ]; then CFG_PATH="$TARGET/opencode.jsonc"
else CFG_PATH="$TARGET/opencode.json"; fi

CREATED_CFG=false
BACKUP=""
if [ -f "$CFG_PATH" ]; then
  STAMP="$(date +%Y%m%d-%H%M%S)"
  BACKUP="$CFG_PATH.aie-backup-$STAMP"
  cp -f "$CFG_PATH" "$BACKUP"
  say "Backed up $CFG_PATH to $BACKUP"
else
  : > "$CFG_PATH"
  CREATED_CFG=true
  say "No pre-existing config to back up; created $CFG_PATH"
fi

ADDED_AGENTS='[]'; SKIPPED_AGENTS='[]'
ADDED_CMDS='[]'; SKIPPED_CMDS='[]'
ADDED_INS='[]'

MANAGED_REF="$(printf '%s' "$MANAGED" | sed 's#\\#/#g')"

PAYLOAD_AGENTS="{}"
  for k in "${AGENT_KEYS[@]}"; do
    if jq -e --arg k "$k" '.agent[$k] != null' "$CFG_PATH" >/dev/null 2>&1; then
      SKIPPED_AGENTS="$(printf '%s\n%s' "$SKIPPED_AGENTS" "$(jq -n --arg k "$k" '[$k]')" | jq -s 'add')"
      continue
    fi
    ADDED_AGENTS="$(printf '%s\n%s' "$ADDED_AGENTS" "$(jq -n --arg k "$k" '[$k]')" | jq -s 'add')"
    desc="$(agent_desc "$k")"
    PAYLOAD_AGENTS="$(jq -n --arg k "$k" --arg d "$desc" --arg p "$MANAGED_REF/agents/$k.txt" \
      -c --argjson v '{"mode":"subagent","tools":{"read":true,"bash":true,"write":false,"edit":false}}' \
      '. + { ($k): ($v + {description:$d, prompt:("{file:" + $p + "}")}) }' <<<"$PAYLOAD_AGENTS")"
  done

  PAYLOAD_CMDS="{}"
  for k in "${COMMAND_KEYS[@]}"; do
    if jq -e --arg k "$k" '.command[$k] != null' "$CFG_PATH" >/dev/null 2>&1; then
      SKIPPED_CMDS="$(printf '%s\n%s' "$SKIPPED_CMDS" "$(jq -n --arg k "$k" '[$k]')" | jq -s 'add')"
      continue
    fi
    ADDED_CMDS="$(printf '%s\n%s' "$ADDED_CMDS" "$(jq -n --arg k "$k" '[$k]')" | jq -s 'add')"
    IFS='|' read -r desc ag <<<"$(cmd_args "$k")"
    PAYLOAD_CMDS="$(jq -n --arg k "$k" --arg d "$desc" --arg a "$ag" --arg p "$MANAGED_REF/commands/$k.md" \
      -c --argjson v '{"subtask":true}' \
      '. + { ($k): ($v + {description:$d, agent:$a, template:("{file:" + $p + "}\n\n$ARGUMENTS")}) }' <<<"$PAYLOAD_CMDS")"
  done

  # instructions as absolute refs into the managed subdir
  ADDED_INS='[]'
  for ins in "$MANAGED_REF/AGENTS.md" "$MANAGED_REF/INSTRUCTIONS.md"; do
    if jq -e --arg i "$ins" '.instructions | index($i) == null | not' "$CFG_PATH" >/dev/null 2>&1; then
      continue
    fi
    ADDED_INS="$(printf '%s\n%s' "$ADDED_INS" "$(jq -n --arg i "$ins" '[$i]')" | jq -s 'add')"
  done

  jq --argjson agents "$PAYLOAD_AGENTS" \
     --argjson cmds   "$PAYLOAD_CMDS" \
     --argjson ins    "$ADDED_INS" \
     '
       . as $root
       | .agent   = (($root.agent // {}) + $agents)
       | .command = (($root.command // {}) + $cmds)
       | .instructions = (($root.instructions // []) + $ins | unique)
     ' "$CFG_PATH" > "$CFG_PATH.tmp" && mv "$CFG_PATH.tmp" "$CFG_PATH"
  say "Merged config into $CFG_PATH"

# marker
jq -n \
  --arg pkg "$PKG" \
  --arg version "1.0.0" \
  --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg target "$TARGET" \
  --arg managed "$MANAGED" \
  --arg cfg "$CFG_PATH" \
  --arg backup "$BACKUP" \
  --argjson createdCfg "$CREATED_CFG" \
  --argjson addedAgents "$ADDED_AGENTS" \
  --argjson skippedAgents "$SKIPPED_AGENTS" \
  --argjson addedCmds "$ADDED_CMDS" \
  --argjson skippedCmds "$SKIPPED_CMDS" \
  --argjson addedIns "$ADDED_INS" \
  --argjson stagedPlugins "$STAGED_PLUGIN_FILES" \
  --argjson skippedPlugins "$SKIPPED_PLUGIN_FILES" \
  --argjson stagedTools "$STAGED_TOOL_FILES" \
  --argjson skippedTools "$SKIPPED_TOOL_FILES" \
  --argjson stagedSkills "$STAGED_SKILL_DIRS" \
  --argjson skippedSkills "$SKIPPED_SKILL_DIRS" \
  '{package:$pkg, version:$version, installedAt:$now, target:$target, managedPath:$managed,
    configPath:$cfg, backupPath:$backup, createdConfig:$createdCfg,
    addedAgentKeys:$addedAgents, skippedAgentKeys:$skippedAgents,
    addedCommandKeys:$addedCmds, skippedCommandKeys:$skippedCmds,
    addedInstructions:$addedIns, stagedPluginFiles:$stagedPlugins,
    skippedPluginFiles:$skippedPlugins, stagedToolFiles:$stagedTools,
    skippedToolFiles:$skippedTools, stagedSkillDirs:$stagedSkills,
    skippedSkillDirs:$skippedSkills,
    note:"Uninstall: install.sh --uninstall"}' \
  > "$MARKER"
say "Marker written to $MARKER"
say "Install complete for target $TARGET"
say "Restart OpenCode to load the plugin/agents/commands/skills."
say "To reverse: $0 --uninstall"