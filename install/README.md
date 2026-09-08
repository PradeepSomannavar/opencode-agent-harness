# OpenCode Agent Harness — Installer Notes

The `install/` directory contains scripts that copy this package into an OpenCode config
directory and reference it from the config, without clobbering unrelated settings.

> The scripts are provided for you to review and run. They are not executed automatically.

## What an install does

1. Copies the package into `<config-dir>/opencode-agent-harness/` (agents, skills,
   commands, plugins, tools, tests, docs, foundation files).
2. **Stages the runtime spine** into the directories OpenCode actually loads from:
   - `plugins/` → `<config-dir>/plugins/` (OpenCode auto-loads local plugins from
     `<config-dir>/plugins/`, so the package plugin is picked up on restart)
   - `tools/` → `<config-dir>/tools/` (the plugin imports `../tools/*`, so the tools
     must sit at the same level as the plugin — exactly how a hand-configured
     OpenCode config keeps them)
   - `skills/` → `<config-dir>/skills/<name>/` (OpenCode discovers skills from
     `<config-dir>/skills/`)
   Existing plugin files, tool files, or skill directories are skipped, never
   overwritten, and recorded in the marker.
3. Backs up the target `opencode.json`/`opencode.jsonc`.
4. Merges config, never overwriting pre-existing keys, using absolute `{file:...}`
   references into the managed subdir:
   - The 6 review `agent` entries are added only if their names do not already exist
     (existing names are skipped and recorded).
   - The 4 `command` entries are added only if absent.
   - Instructions (`AGENTS.md` / `INSTRUCTIONS.md` inside the managed subdir) are
     added only if not already listed.
   - `default_agent` in an existing config is left untouched.
   - The legacy `plugin`/`skills.paths` config entries are **not** added; local
     plugins and skills load through the convention directories above.
5. Writes a marker file (`<config-dir>/.opencode-agent-harness.marker`) that records
   exactly which keys, plugin files, and skill directories were added or skipped, and
   where the config backup lives.

## Reversal

Run the same script in uninstall mode — it restores the config backup (or removes a
config file the installer created), removes every key and staged plugin/tool/skill
entry it added (skipped entries are untouched), prunes the now-empty directories,
deletes the managed directory, and removes the marker.

- Windows: `.\install\install.ps1 -Uninstall`
- macOS/Linux: `./install/install.sh --uninstall`

## Requirements

- Windows: PowerShell 5.1+ (`install.ps1`) — no external dependencies.
- macOS/Linux: `bash` (3.2+) and `jq` (`install.sh`) — install jq with
  `apt-get install jq`, `brew install jq`, or `winget install jq`.

## Usage

Windows:

```powershell
# default target: %USERPROFILE%\.config\opencode
.\install\install.ps1

# explicit target
.\install\install.ps1 -Target C:\path\to\config
```

macOS/Linux:

```bash
# default target: $HOME/.config/opencode
./install/install.sh

# explicit target
./install/install.sh --target /path/to/config
```

## Requirements

- Windows installer: PowerShell 5.1+ (built-in). JSON merge always attempted; a backup is
  always written first.
- shell installer: `bash` and `jq` (jq is only used for JSON merging; without jq the script
  copies the files, backs up the config, and prints the manual merge steps).

## Safety

- No system-level writes, no services, no background processes, no network access.
- Existing config keys with the same names as package agents/commands are **never**
  overwritten.
- The backup file is retained even after uninstall removal (as `<config>.aie-backup-*`).
- Restart OpenCode after installing for the plugin/agents/commands/skills to load.