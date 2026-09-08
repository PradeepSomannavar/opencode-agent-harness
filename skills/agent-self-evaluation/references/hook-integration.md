# Hook Integration for Session-End Self-Evaluation

## Manual Usage (Recommended)

The most reliable approach is manual invocation — the agent runs self-evaluation as part
of its workflow when the `agent-self-evaluation` skill is active, without requiring any
hook configuration. The skill's "When to Activate" section covers the trigger conditions
(multi-file changes, debugging sessions, design documents).

## Integration with the Python Evaluator

The `scripts/evaluate.py` script can be used as a standalone tool:

```bash
# Pipe agent output directly
echo "Your agent response here" | python3 skills/agent-self-evaluation/scripts/evaluate.py

# From files
python3 skills/agent-self-evaluation/scripts/evaluate.py --task task.txt --output response.txt
```

## Optional Automated Reminder via the Plugin

This package does not run the evaluator automatically. If you maintain the plugin
(`plugins/aie-hooks.ts`) and want a lightweight reminder, add a log line in the existing
`session.idle` handler — it fires when the session becomes idle after a task completes:

```ts
"session.idle": async () => {
  // ... existing audit logic ...
  log("info", "[AIE] Session complete. Consider running the agent-self-evaluation skill to rate your output.")
}
```

No separate hook configuration file is required; the plugin's OpenCode hooks are the
integration point. These reminders are strictly opt-in — the evaluator itself only runs
when the skill is activated.

## Manual Reminder After Shell Verification

If you simply want a nudge after a verification step, state it as part of your workflow
("after running the tests for a non-trivial task, consider the `agent-self-evaluation`
skill") rather than wiring a tool-level hook. This keeps the behavior visible in the
conversation instead of hidden in environment-level configuration.