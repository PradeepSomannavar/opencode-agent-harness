/**
 * AI Engineering Plugin Hooks for OpenCode
 *
 * Hook automation for OpenCode sessions: file-edit hygiene (formatting,
 * console.log warnings, TypeScript checks), pre/post tool logging, session
 * lifecycle logging, context compaction, environment injection, and tool
 * registration.
 */

import type { PluginInput } from "@opencode-ai/plugin"
import * as fs from "fs"
import * as path from "path"
import { fileURLToPath } from "node:url"
import changedFilesTool from "../tools/changed-files.js"
import dependencyAnalyzerTool from "../tools/dependency-analyzer.js"
import runTestsTool from "../tools/run-tests.js"
import checkCoverageTool from "../tools/check-coverage.js"
import securityAuditTool from "../tools/security-audit.js"

/**
 * Type definitions for better type safety
 */
interface ToolArgs {
  filePath?: string
  file_path?: string
  path?: string
  command?: string
  [key: string]: unknown
}

interface ToolInput {
  tool: string
  callID?: string
  args?: ToolArgs
}

interface PermissionEvent {
  tool: string
  args: unknown
}

interface TodoEvent {
  todos: Array<{ text: string; done: boolean }>
}

const PACKAGE_NAME = "opencode-agent-harness"
const DEFAULT_VERSION = "1.0.0"

/**
 * Resolve the directory this module lives in without assuming a module format.
 * The plugin is compiled to ESM (import.meta.url) but may be loaded by tools
 * that evaluate the TypeScript source as CommonJS (__dirname). Returns
 * undefined if neither is available.
 */
function resolvePluginDir(): string | undefined {
  try {
    const d = typeof __dirname === "string" ? __dirname : undefined
    if (d) return path.resolve(d)
  } catch {
    // __dirname not defined (ESM) - fall through
  }
  try {
    return path.dirname(fileURLToPath(import.meta.url))
  } catch {
    // import.meta not available (CommonJS) - fall through
  }
  return undefined
}

/**
 * Read the package version from the nearest package.json that identifies this
 * package. Walks up from the plugin's own directory, so it works both in the
 * repository checkout and after install (config-dir or node_modules layout).
 * Falls back to a default if no matching package.json can be found.
 */
function getPluginVersion(): string {
  const baseDir = resolvePluginDir()
  if (!baseDir) return DEFAULT_VERSION

  let dir = baseDir
  for (;;) {
    const candidate = path.join(dir, "package.json")
    try {
      const pkg = JSON.parse(fs.readFileSync(candidate, "utf-8"))
      if (pkg.name === PACKAGE_NAME && typeof pkg.version === "string" && pkg.version) {
        return pkg.version
      }
    } catch {
      // No readable package.json here - keep walking up
    }
    const parent = path.dirname(dir)
    if (parent === dir) return DEFAULT_VERSION
    dir = parent
  }
}

type AIEHooksPluginFn = (input: PluginInput) => Promise<Record<string, unknown>>

export const AIEHooksPlugin: AIEHooksPluginFn = async ({
  client,
  $,
  directory,
  worktree,
}: PluginInput) => {
  type HookProfile = "minimal" | "standard" | "strict"

  const worktreePath = worktree || directory

  const editedFiles = new Set<string>()

  function resolvePath(p: string): string {
    if (path.isAbsolute(p)) return p
    return path.join(worktreePath, p)
  }

  function hasProjectFile(relativePath: string): boolean {
    try {
      return fs.statSync(resolvePath(relativePath)).isFile()
    } catch {
      return false
    }
  }

  const pendingToolChanges = new Map<string, { path: string; type: "added" | "modified" }>()
  let writeCounter = 0

  function getFilePath(args: ToolArgs | undefined): string | null {
    if (!args) return null
    const p = (args.filePath ?? args.file_path ?? args.path) as string | undefined
    return typeof p === "string" && p.trim() ? p : null
  }

  /**
   * Cross-platform console.log scan. Avoids shelling out to `grep`, which is
   * not available in the default Windows shell.
   */
  function countConsoleLogs(file: string): number | null {
    try {
      const content = fs.readFileSync(resolvePath(file), "utf-8")
      return content.split("\n").filter((line) => line.includes("console.log")).length
    } catch {
      return null
    }
  }

  // Helper to call the SDK's log API with correct signature
  const log = (level: "debug" | "info" | "warn" | "error", message: string) =>
    client.app.log({ body: { service: "aie", level, message } })

  // Loaded lazily (instead of via a top-level import) so that a missing or
  // partially-installed plugins `lib` directory (e.g. an interrupted or
  // partial install) only disables changed-files tracking, rather than
  // throwing during module evaluation. This plugin is OpenCode's startup
  // entry point, so a static import failure here previously crashed the whole
  // plugin -- and with it, the entire OpenCode session -- before any hooks
  // could load.
  let changedFilesStore: typeof import("./lib/changed-files-store.js") | undefined
  try {
    const store = await import("./lib/changed-files-store.js")
    store.initStore(worktreePath)
    changedFilesStore = store
  } catch {
    // Best-effort diagnostic only: deferred via .then() (rather than
    // Promise.resolve(log(...))) so that even a *synchronous* throw inside
    // log() -- not just an async rejection -- is caught here instead of
    // escaping this catch block. The raw loader error is intentionally not
    // included in the message since it can contain absolute filesystem
    // paths; this whole block exists to guarantee startup resilience even
    // when things go wrong.
    Promise.resolve()
      .then(() =>
        log(
          "warn",
          "[AIE] changed-files tracking disabled: could not load the changed-files store. " +
            "Reinstall the opencode-agent-harness package to restore the missing files. Other plugin hooks are unaffected."
        )
      )
      .catch(() => {})
  }

  const normalizeProfile = (value: string | undefined): HookProfile => {
    if (value === "minimal" || value === "strict") return value
    return "standard"
  }

  const currentProfile = normalizeProfile(process.env.AIE_HOOK_PROFILE)
  const disabledHooks = new Set(
    (process.env.AIE_DISABLED_HOOKS || "")
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean)
  )

  const profileOrder: Record<HookProfile, number> = {
    minimal: 0,
    standard: 1,
    strict: 2,
  }

  const profileAllowed = (required: HookProfile | HookProfile[]): boolean => {
    if (Array.isArray(required)) {
      return required.some((entry) => profileOrder[currentProfile] >= profileOrder[entry])
    }
    return profileOrder[currentProfile] >= profileOrder[required]
  }

  const hookEnabled = (
    hookId: string,
    requiredProfile: HookProfile | HookProfile[] = "standard"
  ): boolean => {
    if (disabledHooks.has(hookId)) return false
    return profileAllowed(requiredProfile)
  }

  return {
    /**
     * Prettier Auto-Format Hook (file.edited)
     *
     * Triggers: After any JS/TS/JSX/TSX file is edited
     * Action: Runs prettier --write on the file
     */
    "file.edited": async (event: { path: string }) => {
      editedFiles.add(event.path)
      changedFilesStore?.recordChange(event.path, "modified")

      // Auto-format JS/TS files
      if (hookEnabled("post:edit:format", ["strict"]) && event.path.match(/\.(ts|tsx|js|jsx)$/)) {
        try {
          await $`prettier --write ${event.path}`
          log("info", `[AIE] Formatted: ${event.path}`)
        } catch (error: unknown) {
          // Prettier not installed or failed - log but continue
          const errorMessage = error instanceof Error ? error.message : String(error)
          log("debug", `[AIE] Prettier formatting failed for ${event.path}: ${errorMessage}`)
        }
      }

      // Console.log warning check
      if (hookEnabled("post:edit:console-warn", ["standard", "strict"]) && event.path.match(/\.(ts|tsx|js|jsx)$/)) {
        const count = countConsoleLogs(event.path)
        if (count !== null && count > 0) {
          log(
            "warn",
            `[AIE] console.log found in ${event.path} (${count} occurrence${count > 1 ? "s" : ""})`
          )
        }
      }
    },

    /**
     * TypeScript Check Hook (tool.execute.after)
     *
     * Triggers: After edit tool completes on .ts/.tsx files
     * Action: Runs tsc --noEmit to check for type errors
     */
    "tool.execute.after": async (
      input: ToolInput,
      output: unknown
    ) => {
      const filePath = getFilePath(input.args)
      if (input.tool === "edit" && filePath) {
        changedFilesStore?.recordChange(filePath, "modified")
      }
      if (input.tool === "write" && filePath) {
        const key = input.callID ?? `write-${++writeCounter}-${filePath}`
        const pending = pendingToolChanges.get(key)
        if (pending) {
          changedFilesStore?.recordChange(pending.path, pending.type)
          pendingToolChanges.delete(key)
        } else {
          changedFilesStore?.recordChange(filePath, "modified")
        }
      }

      // Check if a TypeScript file was edited
      if (
        hookEnabled("post:edit:typecheck", ["strict"]) &&
        input.tool === "edit" &&
        input.args?.filePath?.match(/\.tsx?$/)
      ) {
        try {
          await $`npx tsc --noEmit 2>&1`
          log("info", "[AIE] TypeScript check passed")
        } catch (error: unknown) {
          const err = error as { stdout?: string }
          log("warn", "[AIE] TypeScript errors detected:")
          if (err.stdout) {
            // Log first few errors
            const errors = err.stdout.split("\n").slice(0, 5)
            errors.forEach((line: string) => log("warn", `  ${line}`))
          }
        }
      }

      // PR creation logging
      if (
        hookEnabled("post:bash:pr-created", ["standard", "strict"]) &&
        input.tool === "bash" &&
        input.args?.toString().includes("gh pr create")
      ) {
        log("info", "[AIE] PR created - check GitHub Actions status")
      }
    },

    /**
     * Pre-Tool Security Check (tool.execute.before)
     *
     * Triggers: Before tool execution
     * Action: Warns about potential security issues
     */
    "tool.execute.before": async (
      input: ToolInput
    ) => {
      if (input.tool === "write") {
        const filePath = getFilePath(input.args)
        if (filePath) {
          const absPath = resolvePath(filePath)
          let type: "added" | "modified" = "modified"
          try {
            if (typeof fs.existsSync === "function") {
              type = fs.existsSync(absPath) ? "modified" : "added"
            }
          } catch {
            type = "modified"
          }
          const key = input.callID ?? `write-${++writeCounter}-${filePath}`
          pendingToolChanges.set(key, { path: filePath, type })
        }
      }

      // Git push review reminder
      if (
        hookEnabled("pre:bash:git-push-reminder", "strict") &&
        input.tool === "bash" &&
        input.args?.toString().includes("git push")
      ) {
        log(
          "info",
          "[AIE] Remember to review changes before pushing: git diff origin/main...HEAD"
        )
      }

      // Block creation of unnecessary documentation files
      if (
        hookEnabled("pre:write:doc-file-warning", ["standard", "strict"]) &&
        input.tool === "write" &&
        input.args?.filePath &&
        typeof input.args.filePath === "string"
      ) {
        const filePath = input.args.filePath
        if (
          filePath.match(/\.(md|txt)$/i) &&
          !filePath.includes("README") &&
          !filePath.includes("CHANGELOG") &&
          !filePath.includes("LICENSE") &&
          !filePath.includes("CONTRIBUTING")
        ) {
          log(
            "warn",
            `[AIE] Creating ${filePath} - consider if this documentation is necessary`
          )
        }
      }

      // Long-running command reminder
      if (hookEnabled("pre:bash:tmux-reminder", "strict") && input.tool === "bash") {
        const cmd = String(input.args?.command || input.args || "")
        if (
          cmd.match(/^(npm|pnpm|yarn|bun)\s+(install|build|test|run)/) ||
          cmd.match(/^cargo\s+(build|test|run)/) ||
          cmd.match(/^go\s+(build|test|run)/)
        ) {
          log(
            "info",
            "[AIE] Long-running command detected - consider using background execution"
          )
        }
      }
    },

    /**
     * Session Created Hook (session.created)
     *
     * Triggers: When a new session starts
     * Action: Loads context and displays welcome message
     */
    "session.created": async () => {
      if (!hookEnabled("session:start", ["minimal", "standard", "strict"])) return

      log("info", `[AIE] Session started - profile=${currentProfile}`)

      // Check for project-specific context files
      if (hasProjectFile("AGENTS.md") || hasProjectFile("INSTRUCTIONS.md")) {
        log("info", "[AIE] Found project instructions - loading project context")
      }
    },

    /**
     * Session Idle Hook (session.idle)
     *
     * Triggers: When session becomes idle (task completed)
     * Action: Runs console.log audit on all edited files
     */
    "session.idle": async () => {
      if (!hookEnabled("stop:check-console-log", ["minimal", "standard", "strict"])) return
      if (editedFiles.size === 0) return

      log("info", "[AIE] Session idle - running console.log audit")

      let totalConsoleLogCount = 0
      const filesWithConsoleLogs: string[] = []

      for (const file of editedFiles) {
        if (!file.match(/\.(ts|tsx|js|jsx)$/)) continue

        const count = countConsoleLogs(file)
        if (count !== null && count > 0) {
          totalConsoleLogCount += count
          filesWithConsoleLogs.push(file)
        }
      }

      if (totalConsoleLogCount > 0) {
        log(
          "warn",
          `[AIE] Audit: ${totalConsoleLogCount} console.log statement(s) in ${filesWithConsoleLogs.length} file(s)`
        )
        filesWithConsoleLogs.forEach((f) =>
          log("warn", `  - ${f}`)
        )
        log("warn", "[AIE] Remove console.log statements before committing")
      } else {
        log("info", "[AIE] Audit passed: No console.log statements found")
      }

      // Desktop notification (cross-platform)
      try {
        if (process.platform === "darwin") {
          // macOS
          await $`osascript -e 'display notification "Task completed!" with title "OpenCode Agent Harness"'`
        } else if (process.platform === "win32") {
          // Windows - PowerShell notification
          await $`powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('Task completed!', 'OpenCode Agent Harness', 'OK', 'Information')"`
        } else if (process.platform === "linux") {
          // Linux - notify-send (requires libnotify)
          await $`notify-send "OpenCode Agent Harness" "Task completed!"`
        }
      } catch (error: unknown) {
        // Notification not supported or failed - log but continue
        const errorMessage = error instanceof Error ? error.message : String(error)
        log("debug", `[AIE] Desktop notification failed: ${errorMessage}`)
      }

      // Clear tracked files for next task
      editedFiles.clear()
    },

    /**
     * Session Deleted Hook (session.deleted)
     *
     * Triggers: When session ends
     * Action: Final cleanup and state saving
     */
    "session.deleted": async () => {
      if (!hookEnabled("session:end-marker", ["minimal", "standard", "strict"])) return
      log("info", "[AIE] Session ended - cleaning up")
      editedFiles.clear()
      changedFilesStore?.clearChanges()
      pendingToolChanges.clear()
    },

    /**
     * File Watcher Hook (file.watcher.updated)
     *
     * Triggers: When file system changes are detected
     * Action: Updates tracking
     */
    "file.watcher.updated": async (event: { path: string; type: string }) => {
      let changeType: "added" | "modified" | "deleted" = "modified"
      if (event.type === "create" || event.type === "add") changeType = "added"
      else if (event.type === "delete" || event.type === "remove") changeType = "deleted"
      changedFilesStore?.recordChange(event.path, changeType)
      if (event.type === "change" && event.path.match(/\.(ts|tsx|js|jsx)$/)) {
        editedFiles.add(event.path)
      }
    },

    /**
     * Todo Updated Hook (todo.updated)
     *
     * Triggers: When todo list is updated
     * Action: Logs progress
     */
    "todo.updated": async (event: TodoEvent) => {
      const completed = event.todos.filter((t) => t.done).length
      const total = event.todos.length
      if (total > 0) {
        log("info", `[AIE] Progress: ${completed}/${total} tasks completed`)
      }
    },

    /**
     * Shell Environment Hook (shell.env)
     *
     * Triggers: Before shell command execution
     * Action: Sets AIE_*, PROJECT_ROOT, PACKAGE_MANAGER, DETECTED_LANGUAGES
     *
     * Only writes AIE_* environment variables. Reads AIE_* inputs (hook profile,
     * disabled hooks) when provided.
     */
    "shell.env": async () => {
      const env: Record<string, string> = {
        AIE_VERSION: getPluginVersion(),
        AIE_PLUGIN: "true",
        AIE_HOOK_PROFILE: currentProfile,
        AIE_DISABLED_HOOKS: process.env.AIE_DISABLED_HOOKS || "",
        PROJECT_ROOT: worktreePath,
      }

      // Detect package manager
      const lockfiles: Record<string, string> = {
        "bun.lockb": "bun",
        "pnpm-lock.yaml": "pnpm",
        "yarn.lock": "yarn",
        "package-lock.json": "npm",
      }
      for (const [lockfile, pm] of Object.entries(lockfiles)) {
        if (hasProjectFile(lockfile)) {
          env.PACKAGE_MANAGER = pm
          break
        }
      }

      // Detect languages
      const langDetectors: Record<string, string> = {
        "tsconfig.json": "typescript",
        "go.mod": "go",
        "pyproject.toml": "python",
        "Cargo.toml": "rust",
        "Package.swift": "swift",
      }
      const detected: string[] = []
      for (const [file, lang] of Object.entries(langDetectors)) {
        if (hasProjectFile(file)) {
          detected.push(lang)
        }
      }
      if (detected.length > 0) {
        env.DETECTED_LANGUAGES = detected.join(",")
        env.PRIMARY_LANGUAGE = detected[0]
      }

      return env
    },

    /**
     * Session Compacting Hook (experimental.session.compacting)
     *
     * Triggers: Before context compaction
     * Action: Push AIE context block and custom compaction prompt
     */
    "experimental.session.compacting": async () => {
      const contextBlock = [
        "# AIE Context (preserve across compaction)",
        "",
        "## Active Plugin: opencode-agent-harness",
        "- Hooks: file.edited, tool.execute.before/after, session.created/idle/deleted, shell.env, compacting, permission.ask",
        "- Tools: run-tests, check-coverage, security-audit, format-code, lint-check, git-summary, changed-files",
        "- Agents: build, ai-architect, ai-security-reviewer, agent-evaluator, code-architect, mle-reviewer, rag-pipeline-reviewer",
        "",
        "## Key Principles",
        "- TDD: write tests first, 80%+ coverage",
        "- Immutability: never mutate, always return new copies",
        "- Security: validate inputs, no hardcoded secrets",
        "",
      ]

      // Include recently edited files
      if (editedFiles.size > 0) {
        contextBlock.push("## Recently Edited Files")
        for (const f of editedFiles) {
          contextBlock.push(`- ${f}`)
        }
        contextBlock.push("")
      }

      return {
        context: contextBlock.join("\n"),
        compaction_prompt: "Focus on preserving: 1) Current task status and progress, 2) Key decisions made, 3) Files created/modified, 4) Remaining work items, 5) Any security concerns flagged. Discard: verbose tool outputs, intermediate exploration, redundant file listings.",
      }
    },

    /**
     * Permission Auto-Approve Hook (permission.ask)
     *
     * Triggers: When permission is requested
     * Action: Auto-approve reads, formatters, and test commands; log all for audit
     */
    "permission.ask": async (event: PermissionEvent) => {
      log("info", `[AIE] Permission requested for: ${event.tool}`)

      try {
        // Handle both string args and object args with command property
        let cmd: string
        if (typeof event.args === "string") {
          cmd = event.args
        } else if (event.args && typeof event.args === "object") {
          cmd = String((event.args as Record<string, unknown>).command || "")
        } else {
          cmd = String(event.args || "")
        }

        // Auto-approve: read/search tools
        if (["read", "glob", "grep", "search", "list"].includes(event.tool)) {
          log("debug", `[AIE] Auto-approved read-only tool: ${event.tool}`)
          return { approved: true, reason: "Read-only operation" }
        }

        // Auto-approve: formatters
        if (event.tool === "bash" && /^(npx )?(@biomejs\/biome|prettier|black|gofmt|rustfmt|swift-format)/.test(cmd)) {
          log("debug", `[AIE] Auto-approved formatter: ${cmd}`)
          return { approved: true, reason: "Formatter execution" }
        }

        // Auto-approve: test execution
        if (event.tool === "bash" && /^(npm test|npx vitest|npx jest|pytest|go test|cargo test)/.test(cmd)) {
          log("debug", `[AIE] Auto-approved test execution: ${cmd}`)
          return { approved: true, reason: "Test execution" }
        }

        // Everything else: let user decide
        log("debug", `[AIE] Permission requires user approval: ${event.tool}`)
        return { approved: undefined }
      } catch (error: unknown) {
        // Error in permission handling - log and deny for safety
        const errorMessage = error instanceof Error ? error.message : String(error)
        log("error", `[AIE] Permission handling error for ${event.tool}: ${errorMessage}`)
        return { approved: false, reason: `Error: ${errorMessage}` }
      }
    },

    tool: {
      "changed-files": changedFilesTool,
      "dependency-analyzer": dependencyAnalyzerTool,
      "run-tests": runTestsTool,
      "check-coverage": checkCoverageTool,
      "security-audit": securityAuditTool,
    },
  }
}

export default AIEHooksPlugin