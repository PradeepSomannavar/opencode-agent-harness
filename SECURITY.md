# Security Policy

## Reporting a vulnerability

If you find a security issue in OpenCode Agent Harness:

- **Do not** open a public issue for exploitable vulnerabilities.
- Report it privately by opening a [security advisory][advisories] on the GitHub
  repository, or by opening an issue with the lowest visibility and marking it
  security-related.

Indicate the affected component (plugin, tool, installer, command template) and,
if possible, a minimal reproduction. You will receive an acknowledgment normally
within one week.

[advisories]: https://github.com/PradeepSomannavar/opencode-agent-harness/security/advisories

## What this project does

- **No secrets.** Nothing in the repository reads, stores, or transmits API keys or
  credentials. It uses whatever model provider OpenCode is already configured with.
- **No network.** The plugin and tools make no network calls and run no telemetry.
- **No external runtime.** Everything runs inside the configured OpenCode
  environment using Node built-ins and the OpenCode plugin API.
- **Read-only review agents.** All subagents other than `build` have no write or
  edit tools.
- **Ask-before-MCP.** `opencode.json` sets `"permission": { "mcp_*": "ask" }` so MCP
  access requires approval.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | Yes |

## Security expectations

- Prompt-injection resistance of generated reviews is a property of the model being
  used, not of this package. Reviews are advisory output for a human to verify.
- Installers copy files into the OpenCode config directory and never run code they
  do not copy. Review the installer source before running it.