# Contributing

Thanks for contributing to OpenCode Agent Harness.

## Repository layout

```
agents/     agent system prompts (*.txt)
commands/   command templates (*.md)
skills/     skills (<name>/SKILL.md)
tools/      OpenCode tools (*.ts)
plugins/    plugin code (*.ts)
tests/      self-check script
install/    installers
docs/       public references
examples/   example prompts
```

## Adding an agent

1. Create `agents/<name>.txt` with the agent system prompt.
2. Register the entry under `agent` in `opencode.json` (`mode: subagent`,
   `{file:agents/<name>.txt}`, read-only tool set unless the agent must write).
3. Optionally bind it to a command.
4. Update `docs/AGENTS.md`.
5. Run `npm run verify`.

## Adding a command

1. Create `commands/<name>.md` with the command template.
2. Register it under `command` in `opencode.json` (`agent`, `subtask: true`,
   `{file:commands/<name>.md}`).
3. Update `docs/COMMANDS.md`.
4. Run `npm run verify`.

## Adding a skill

1. Create `skills/<name>/SKILL.md` with a YAML frontmatter block:

   ```yaml
   ---
   name: <skill-name>
   description: When to use this skill, in plain language.
   ---
   ```

2. Skills under `skills/` register automatically via `skills.paths`.
3. Update `docs/SKILLS.md`.
4. Run `npm run verify`.

## Rules

- **Keep it self-contained.** No personal machine paths, no environment-specific
  paths, no references to repositories that are not part of this project, and no
  secrets anywhere in the repository.
- **No runtime dependencies beyond Node built-ins and the OpenCode plugin API.**
  Import checks in `verify-package.mjs` enforce this.
- **Keep review agents read-only.** Only `build` (the primary agent) writes or edits
  projects.
- **Provide an install marker + uninstall path** for anything the installers touch.

## Verifying your change

```bash
npm install
npm run verify   # package self-check (agents, commands, skills, imports, self-containment)
npm run build    # TypeScript build to dist/
npm pack --dry-run  # inspect the publishable artifact
```

Every failure is FATAL — fix, don't bypass.

## Commit style

Conventional commits, matching the repo history:

- `feat: ...` new capability
- `fix: ...` bug fix
- `docs: ...` documentation
- `test: ...` tests / self-check
- `chore: ...` tooling / housekeeping
- `perf: ...` performance

## Proposing a change

1. Fork the repository and create a feature branch.
2. Make the change and verify it (commands above).
3. Open a pull request with a clear description of the change and the verification
   you ran.