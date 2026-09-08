#!/usr/bin/env node
/**
 * verify-package.mjs
 *
 * Package self-check for opencode-agent-harness. Run from the package root:
 *   node tests/verify-package.mjs
 *
 * Checks (minimum contract):
 *   1. opencode.json parses
 *   2. all 7 agents resolve
 *   3. all 4 commands resolve
 *   4. all 15 skills resolve
 *   5. no referenced file missing
 *   6. no selected component references dropped components
 *   7. no personal Windows paths
 *   8. no benchmark-repo refs
 *   9. plugin/tool imports valid
 *  10. structure matches manifest
 *  + self-contained scan across package contents
 */

import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");

const SHIP_AGENTS = ["build", "ai-architect", "rag-pipeline-reviewer", "mle-reviewer", "agent-evaluator", "ai-security-reviewer", "code-architect"];
const SHIP_COMMANDS = ["ai-review", "rag-review", "eval-run", "ai-security"];
const SHIP_SKILLS = [
  "agent-evaluation", "agent-introspection-debugging", "agent-self-evaluation",
  "ai-architecture", "ai-regression-testing", "ai-security", "context-budget",
  "cost-latency-optimization", "eval-harness", "llm-observability", "mcp-development",
  "mle-workflow", "prompt-engineering", "strategic-compact", "verification-loop",
];
const SHIP_TOOLS = ["changed-files", "check-coverage", "dependency-analyzer", "format-code", "git-summary", "index", "lint-check", "run-tests", "security-audit"];

// Dropped component names: hard dependency if referenced in shipping content.
const DROPPED_AGENTS = [
  "planner", "architect", "code-reviewer", "security-reviewer", "tdd-guide",
  "build-error-resolver", "e2e-runner", "doc-updater", "refactor-cleaner",
  "go-reviewer", "go-build-resolver", "database-reviewer", "cpp-reviewer",
  "cpp-build-resolver", "docs-lookup", "harness-optimizer", "java-reviewer",
  "java-build-resolver", "kotlin-reviewer", "kotlin-build-resolver", "loop-operator",
  "php-reviewer", "python-reviewer", "rust-reviewer", "rust-build-resolver",
  "performance-optimizer", "pr-test-analyzer", "silent-failure-hunter",
  "a11y-architect", "documentation-lookup", "pytorch-build-resolver", "rag-engineer",
];
const DROPPED_SKILLS = [
  "rag-engineering", "llm-evaluation", "tdd-workflow", "e2e-testing", "ai-regression-testing-extra",
  "unified-memory", "continuous-learning", "continuous-learning-v2", "ck", "skill-comply",
  "agent-sort", "config-gc", "context-budget-x", "council", "dev-team", "delivery-gate",
];

// Self-containment tokens that must NOT appear in shipping content
// (README provenance + install/ are documentation-of-record, excluded below).
const SELF_TOKENS = [
  "C:\\Users", "C:/Users", "ecc-opencode-test", "benchmark-v1", "evals/phase3",
  "ECC v2.2.1", "ecc-universal", "ecc repair", "OpenCode ECC", "mcp-configs",
  "homunculus", ".pi/", "ECC repo",
];
const DROPPED_COMMANDS = ["orchestrate", "learn", "checkpoint", "verify", "eval", "test-coverage", "instinct-status", "instinct-import", "instinct-export", "evolve", "promote", "projects"];

function walk(dir, out = []) {
  for (const e of readdirSync(dir)) {
    if (e === ".git") continue;
    const p = join(dir, e);
    if (statSync(p).isDirectory()) walk(p, out);
    else out.push(p);
  }
  return out;
}

function contentOf(files) {
  const out = {};
  for (const f of files) {
    try { out[f] = readFileSync(f, "utf8"); } catch { /* skip binary/symlink */ }
  }
  return out;
}

const failures = [];
const total = { n: 0 };
function check(name, ok, detail) {
  total.n += 1;
  console.log((ok ? "PASS" : "FAIL") + "  " + name + (ok ? "" : "  -> " + detail));
  if (!ok) failures.push(name);
}

// ---- 1. opencode.json parses ----
let cfg = null;
try { cfg = JSON.parse(readFileSync(join(ROOT, "opencode.json"), "utf8")); } catch (e) {}
check("1. opencode.json parses", !!cfg, cfg ? "" : "invalid JSON");

// ---- 2 / 3. agents + commands resolve ----
if (cfg) {
  const agents = Object.keys(cfg.agent || {});
  const commands = Object.keys(cfg.command || {});
  check("2. all 7 agents resolve", SHIP_AGENTS.every((a) => agents.includes(a)) && agents.length === SHIP_AGENTS.length, "agent keys: " + agents.join(","));
  check("3. all 4 commands resolve", SHIP_COMMANDS.every((c) => commands.includes(c)) && commands.length === SHIP_COMMANDS.length, "command keys: " + commands.join(","));

  // default_agent + build present
  check("2b. default_agent is build", cfg.default_agent === "build", String(cfg.default_agent));

  // instructions only AGENTS.md + INSTRUCTIONS.md
  const ins = cfg.instructions || [];
  check("2c. instructions = [AGENTS.md, INSTRUCTIONS.md] only", ins.length === 2 && ins[0] === "AGENTS.md" && ins[1] === "INSTRUCTIONS.md", ins.join(","));

  // subagent prompts all subtask + file refs inside package
  const badMode = Object.entries(cfg.agent || {}).filter(([n, a]) => n !== "build" && a.mode !== "subagent");
  check("2d. review agents are subagents", badMode.length === 0, badMode.map(([n]) => n).join(","));
}

// ---- 4. skills + 10. structure ----
const skillDirs = readdirSync(join(ROOT, "skills")).filter((e) => statSync(join(ROOT, "skills", e)).isDirectory());
check("4. all 15 skills resolve", SHIP_SKILLS.every((s) => skillDirs.includes(s)) && skillDirs.length === SHIP_SKILLS.length, skillDirs.join(","));
check("4b. each skill has SKILL.md", SHIP_SKILLS.every((s) => existsSync(join(ROOT, "skills", s, "SKILL.md"))));
const toolsFiles = readdirSync(join(ROOT, "tools")).filter((e) => !statSync(join(ROOT, "tools", e)).isDirectory()).map((f) => f.replace(/\.ts$/, "")).sort();
check("10a. tools match manifest", JSON.stringify(toolsFiles) === JSON.stringify(SHIP_TOOLS.map((t) => t).sort()), toolsFiles.join(","));
const agentFiles = readdirSync(join(ROOT, "agents")).filter((e) => !statSync(join(ROOT, "agents", e)).isDirectory()).map((f) => f.replace(/\.txt$/, "")).sort();
check("10b. agents/ files match manifest", JSON.stringify(agentFiles) === JSON.stringify([...SHIP_AGENTS].sort()), agentFiles.join(","));
const cmdFiles = readdirSync(join(ROOT, "commands")).filter((e) => !statSync(join(ROOT, "commands", e)).isDirectory()).map((f) => f.replace(/\.md$/, "")).sort();
check("10c. commands/ files match manifest", JSON.stringify(cmdFiles) === JSON.stringify([...SHIP_COMMANDS].sort()), cmdFiles.join(","));

const expectedTop = ["AGENTS.md", "CHANGELOG.md", "CONTRIBUTING.md", "INSTRUCTIONS.md", "LICENSE", "README.md", "SECURITY.md", "agents", "commands", "docs", "examples", "index.ts", "install", "opencode.json", "package.json", "plugins", "skills", "tests", "tools", "tsconfig.json"];
const topEntries = readdirSync(ROOT)
  .filter((e) => e !== "node_modules" && e !== "package-lock.json" && e !== "dist" && e !== ".git" && e !== ".gitignore" && e !== ".gitattributes" && e !== ".github")
  .sort();
check("10d. package root matches manifest", JSON.stringify(topEntries) === JSON.stringify([...expectedTop].sort()), topEntries.join(","));

// ---- 5. no referenced file missing ----
if (cfg) {
  let refsMissing = "";
  const refs = [...(cfg.instructions || [])];
  for (const a of Object.values(cfg.agent || {})) { const m = a.prompt && a.prompt.match(/^\{file:([^}]+)\}$/); if (m) refs.push(m[1]); }
  for (const c of Object.values(cfg.command || {})) { const m = c.template && c.template.match(/^\{file:([^}]+)\}/); if (m) refs.push(m[1]); }
  for (const r of refs) if (!existsSync(join(ROOT, r))) refsMissing += r + "; ";
  check("5. no referenced file missing", refsMissing === "", refsMissing);
}

// ---- 6. no refs to dropped components ----
const scanTargets = walk(join(ROOT, "agents")).concat(walk(join(ROOT, "commands")), walk(join(ROOT, "skills")));
const scanContent = contentOf(scanTargets);
const droppedRefs = [];
for (const [f, c] of Object.entries(scanContent)) {
  if (!c) continue;
  for (const d of DROPPED_AGENTS) {
    const re = new RegExp("`" + d + "`|\\b\\{\\{" + d + "\\}\\}");
    if (re.test(c)) droppedRefs.push(f + " -> `" + d + "`");
  }
  for (const s of DROPPED_SKILLS) {
    const re = new RegExp("`" + s + "`");
    if (re.test(c)) droppedRefs.push(f + " -> `" + s + "`");
  }
  for (const cm of DROPPED_COMMANDS) {
    const re = new RegExp("(?<![\\w>/])/(" + cm + ")\\b");
    if (re.test(c)) droppedRefs.push(f + " -> /" + cm);
  }
}
check("6. no selected component references dropped components", droppedRefs.length === 0, droppedRefs.slice(0, 5).join("; "));

// ---- 7+8+self-containment scan (exclude README + install = documentation of record) ----
const allFiles = walk(ROOT).filter((f) =>
  !f.includes(join("README.md")) && !f.startsWith(join(ROOT, "install")) &&
  !f.includes("verify-package.mjs") &&
  !f.includes(join("node_modules")) && !f.startsWith(join(ROOT, "dist"))
);
const allContent = contentOf(allFiles);
const selfHits = [];
for (const [f, c] of Object.entries(allContent)) {
  if (!c) continue;
  const rel = f.slice(ROOT.length + 1);
  for (const t of SELF_TOKENS) {
    if (c.includes(t)) selfHits.push(rel + " contains " + JSON.stringify(t));
  }
}
check("7+8. no personal paths / benchmark refs / branding", selfHits.length === 0, selfHits.slice(0, 6).join("; "));

// ---- 9. plugin/tool import validity ----
const pluginToolFiles = walk(join(ROOT, "plugins")).concat(walk(join(ROOT, "tools")), [join(ROOT, "index.ts")]);
const badImports = [];
for (const f of pluginToolFiles) {
  const c = readFileSync(f, "utf8");
  for (const line of c.split("\n")) {
    const m = line.trim().match(/^import\s+(?:[\s\S]*?\s+from\s+)?["']([^"']+)["']/);
    if (!m) continue;
    const spec = m[1];
    if (spec.startsWith("@opencode-ai/plugin") || spec.startsWith(".") || spec.startsWith("node:") || spec === "fs" || spec === "path" || spec === "child_process" || spec === "os") continue;
    badImports.push(f.slice(ROOT.length + 1) + " -> " + spec);
  }
}
check("9. plugin/tool imports valid", badImports.length === 0, badImports.slice(0, 6).join("; "));

// ---- summary ----
console.log("");
console.log(total.n + " checks, " + failures.length + " failure(s)");
if (failures.length) { console.log("FAILED: " + failures.join(" | ")); process.exit(1); }
console.log("PACKAGE VERIFIED");