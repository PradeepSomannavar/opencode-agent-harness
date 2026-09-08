#requires -Version 5.1
<#
.synopsis
  Install or uninstall the opencode-agent-harness package into an OpenCode config dir.

.description
  Merges this package's agents, commands, instructions, plugin, and skills into the
  target OpenCode config directory without clobbering unrelated config.

  OpenCode loads local plugins from <config-dir>/plugins/ (with their sibling runtime
  files resolving from the config dir) and discovers skills in
  <config-dir>/skills/<name>/SKILL.md, so the installer:
    - copies package content into a managed subdir: <target>/opencode-agent-harness/
    - stages the runtime spine into the config dir beneath the convention directories:
      plugins/ and tools/ (the plugin imports ../tools/*, so tools must sit at the
      same level as plugins), plus skills/<name>/ (existing files/dirs are skipped,
      never overwritten)
    - merges agent/command/instructions entries into opencode.json (absolute file refs
      into the managed subdir; pre-existing keys are SKIPPED and recorded)
    - leaves default_agent and everything else in the config untouched

  A marker file (.opencode-agent-harness.marker) records every change so uninstall can
  reverse it exactly (config keys, staged plugin files, staged skill dirs, backup).

  Nothing is installed into system locations, nothing unrelated is touched, and no
  background process is started. Run it, inspect the log, and restart OpenCode.

.example
  .\install\install.ps1
  .\install\install.ps1 -Target C:\path\to\opencode\config
  .\install\install.ps1 -Uninstall
#>
[CmdletBinding()]
param(
  [string]$Target = "",
  [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

function Get-Log-Now { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }
function Write-Log($msg) { Write-Host ("[{0}] {1}" -f (Get-Log-Now), $msg) }

# ---- resolve package root (this script lives in <pkg>/install/) ----
$PackageRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# ---- resolve target config dir ----
if ($Target -eq "") {
  if ($env:XDG_CONFIG_HOME) { $Target = Join-Path $env:XDG_CONFIG_HOME "opencode" }
  elseif ($env:USERPROFILE) { $Target = Join-Path $env:USERPROFILE ".config\opencode" }
  else { throw "Could not determine a default config directory; pass -Target explicitly." }
}
if (-not (Test-Path -LiteralPath $Target)) {
  New-Item -ItemType Directory -Path $Target -Force | Out-Null
}
$Managed = Join-Path $Target "opencode-agent-harness"
$Marker  = Join-Path $Target ".opencode-agent-harness.marker"

# ---- package content to copy ----
$Ship = @("agents", "commands", "skills", "plugins", "tools", "tests", "install", "docs", "examples")
$ShipFiles = @("AGENTS.md", "INSTRUCTIONS.md", "index.ts", "package.json", "tsconfig.json", "README.md", "LICENSE", "opencode.json")

$AgentKeys = @("ai-architect", "rag-pipeline-reviewer", "mle-reviewer", "agent-evaluator", "ai-security-reviewer", "code-architect")
$CommandKeys = @("ai-review", "rag-review", "eval-run", "ai-security")
$Instructions = @("AGENTS.md", "INSTRUCTIONS.md")

# Agent descriptions (kept in sync with agents/*.txt + opencode.json)
$AgentDescriptions = @{
  "ai-architect"          = "AI systems architect specializing in LLM-based systems, RAG pipelines, agentic AI, and GenAI application design. Use for AI feature architecture, model selection, system design, and failure mode analysis."
  "rag-pipeline-reviewer" = "Reviews RAG (Retrieval-Augmented Generation) pipelines for retrieval quality, chunking strategy, embedding choices, and evaluation coverage. Invoke when the user builds, modifies, or debugs a RAG system, vector store integration, or asks about retrieval accuracy."
  "mle-reviewer"          = "Production machine-learning engineering reviewer for data contracts, feature pipelines, training reproducibility, offline/online evaluation, model serving, monitoring, and rollback. Use when ML, MLOps, model training, inference, feature store, or evaluation code changes."
  "agent-evaluator"       = "Evaluates agent output against a 5-axis quality rubric (accuracy, completeness, clarity, actionability, conciseness). Use after a non-trivial task when the user wants a quality assessment. Produces a structured scorecard with evidence and suggested improvements."
  "ai-security-reviewer"  = "AI security specialist for prompt injection, tool abuse, MCP security, and agent privilege escalation. Use when reviewing AI features for security vulnerabilities."
  "code-architect"        = "Designs feature architectures by analyzing existing codebase patterns and conventions, then providing implementation blueprints with concrete files, interfaces, data flow, and build order."
}
$CommandDescriptions = @{
  "ai-review"   = "Review AI system architecture, RAG pipeline, or LLM feature design"
  "rag-review"  = "Review and optimize RAG pipeline (ingestion, chunking, retrieval, generation)"
  "eval-run"    = "Run LLM or agent evaluation against evaluation dataset"
  "ai-security" = "Run AI security review (prompt injection, tool abuse, MCP security)"
}
$CommandAgents = @{
  "ai-review"   = "ai-architect"
  "rag-review"  = "rag-pipeline-reviewer"
  "eval-run"    = "agent-evaluator"
  "ai-security" = "ai-security-reviewer"
}

# ============================================================
# UNINSTALL
# ============================================================
if ($Uninstall) {
  if (-not (Test-Path -LiteralPath $Marker)) { throw "No marker found at $Marker - nothing to uninstall." }
  $markerData = Get-Content -LiteralPath $Marker -Raw | ConvertFrom-Json

  # restore config: remove merged keys, then restore the pre-install backup if present
  $cfgPath = $markerData.configPath
  if (Test-Path -LiteralPath $cfgPath) {
    $raw = Get-Content -LiteralPath $cfgPath -Raw
    $json = $raw | ConvertFrom-Json

    foreach ($k in $markerData.addedAgentKeys) {
      if ($json.agent) { $json.agent.PSObject.Properties.Remove($k) | Out-Null }
    }
    foreach ($k in $markerData.addedCommandKeys) {
      if ($json.command) { $json.command.PSObject.Properties.Remove($k) | Out-Null }
    }
    foreach ($ins in $markerData.addedInstructions) { $json.instructions = @($json.instructions | Where-Object { $_ -ne $ins }) }
    $newCfg = $json | ConvertTo-Json -Depth 12
    Set-Content -LiteralPath $cfgPath -Value $newCfg -Encoding UTF8
    Write-Log "Reversed config changes in $cfgPath"
  }

  # remove staged plugin files, tool files, and skill dirs (only the entries
  # recorded in the marker)
  foreach ($rel in $markerData.stagedPluginFiles) {
    $p = Join-Path $Target $rel
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; Write-Log "Removed staged plugin file $rel" }
  }
  foreach ($rel in $markerData.stagedToolFiles) {
    $p = Join-Path $Target $rel
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; Write-Log "Removed staged tool file $rel" }
  }
  foreach ($rel in $markerData.stagedSkillDirs) {
    $p = Join-Path $Target $rel
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force; Write-Log "Removed staged skill dir $rel" }
  }

  # prune only the directories that are now EMPTY (anything the user pre-existed
  # on is left untouched); deepest dirs first so parents empty out before being checked
  $prunePaths = @("plugins", "tools", "skills")
  foreach ($rel in (@($markerData.stagedPluginFiles) + @($markerData.stagedToolFiles))) {
    $d = Split-Path $rel
    while ($d -and $d -ne "." -and $d -ne "") { $prunePaths += $d; $d = Split-Path $d }
  }
  $pruneOrdered = $prunePaths | Select-Object -Unique | Sort-Object { @($_.Split([char[]]"\/")).Count } -Descending
  foreach ($rel in $pruneOrdered) {
    $p = Join-Path $Target $rel
    if ((Test-Path -LiteralPath $p) -and ((Get-ChildItem -LiteralPath $p -Force | Measure-Object).Count -eq 0)) {
      Remove-Item -LiteralPath $p -Force
      Write-Log "Removed empty staged dir $rel"
    }
  }

  # restore backup if one was taken
  if ($markerData.backupPath -and (Test-Path -LiteralPath $markerData.backupPath)) {
    Copy-Item -LiteralPath $markerData.backupPath -Destination $cfgPath -Force
    Write-Log "Restored config backup from $($markerData.backupPath)"
  } elseif ($markerData.configPath -and (Test-Path -LiteralPath $markerData.configPath) -and $markerData.createdConfig -eq $true) {
    Remove-Item -LiteralPath $markerData.configPath -Force
    Write-Log "Removed config file created by install ($( $markerData.configPath))"
  }
  if ($markerData.managedPath -and (Test-Path -LiteralPath $markerData.managedPath)) { Remove-Item -LiteralPath $markerData.managedPath -Recurse -Force }
  Remove-Item -LiteralPath $Marker -Force
  Write-Log "Uninstall complete. Config restored, staged files removed, managed dir removed, marker deleted."
  exit 0
}

# ============================================================
# INSTALL
# ============================================================
if (Test-Path -LiteralPath $Marker) { throw "opencode-agent-harness appears already installed ($Marker exists). Run with -Uninstall first if you intend to reinstall." }
if (Test-Path -LiteralPath $Managed) { throw "$Managed already exists but no marker was found. Remove it manually if it is stale, then retry." }

# 1. copy package content into managed dir
New-Item -ItemType Directory -Path $Managed -Force | Out-Null
foreach ($d in $Ship) { if (Test-Path -LiteralPath (Join-Path $PackageRoot $d)) { Copy-Item -LiteralPath (Join-Path $PackageRoot $d) -Destination $Managed -Recurse } }
foreach ($f in $ShipFiles) { if (Test-Path -LiteralPath (Join-Path $PackageRoot $f)) { Copy-Item -LiteralPath (Join-Path $PackageRoot $f) -Destination $Managed } }
Write-Log "Copied package into $Managed"

# 2. stage plugin + tools + skills into the OpenCode convention directories
$stagedPluginFiles = @(); $skippedPluginFiles = @()
$stagedToolFiles = @(); $skippedToolFiles = @()
$stagedSkillDirs = @(); $skippedSkillDirs = @()

$pkgPlugins = Join-Path $PackageRoot "plugins"
if (Test-Path -LiteralPath $pkgPlugins) {
  $targetPlugins = Join-Path $Target "plugins"
  New-Item -ItemType Directory -Path $targetPlugins -Force | Out-Null
  $pluginFiles = Get-ChildItem -LiteralPath $pkgPlugins -Recurse -File
  foreach ($pf in $pluginFiles) {
    $rel = $pf.FullName.Substring($pkgPlugins.Length + 1)
    $dest = Join-Path $targetPlugins $rel
    if (Test-Path -LiteralPath $dest) { $skippedPluginFiles += "plugins/$rel" }
    else {
      New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
      Copy-Item -LiteralPath $pf.FullName -Destination $dest -Force
      $stagedPluginFiles += "plugins/$rel"
    }
  }
}

# tools/ is a sibling of plugins/ in the package; the plugin imports "../tools/*",
# so tools must live at the SAME level (the config dir) for the plugin to load.
$pkgTools = Join-Path $PackageRoot "tools"
if (Test-Path -LiteralPath $pkgTools) {
  $targetTools = Join-Path $Target "tools"
  New-Item -ItemType Directory -Path $targetTools -Force | Out-Null
  $toolFiles = Get-ChildItem -LiteralPath $pkgTools -Recurse -File
  foreach ($tf in $toolFiles) {
    $rel = $tf.FullName.Substring($pkgTools.Length + 1)
    $dest = Join-Path $targetTools $rel
    if (Test-Path -LiteralPath $dest) { $skippedToolFiles += "tools/$rel" }
    else {
      New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
      Copy-Item -LiteralPath $tf.FullName -Destination $dest -Force
      $stagedToolFiles += "tools/$rel"
    }
  }
}

$pkgSkills = Join-Path $PackageRoot "skills"
if (Test-Path -LiteralPath $pkgSkills) {
  $targetSkills = Join-Path $Target "skills"
  New-Item -ItemType Directory -Path $targetSkills -Force | Out-Null
  $skillDirs = Get-ChildItem -LiteralPath $pkgSkills -Directory
  foreach ($sd in $skillDirs) {
    $dest = Join-Path $targetSkills $sd.Name
    if (Test-Path -LiteralPath $dest) { $skippedSkillDirs += "skills/$($sd.Name)" }
    else { Copy-Item -LiteralPath $sd.FullName -Destination $dest -Recurse; $stagedSkillDirs += "skills/$($sd.Name)" }
  }
}
if ($stagedPluginFiles.Count -gt 0) { Write-Log ("Staged plugin files into " + (Join-Path $Target "plugins") + ": " + ($stagedPluginFiles -join ", ")) }
if ($stagedToolFiles.Count -gt 0) { Write-Log ("Staged tool files into " + (Join-Path $Target "tools") + ": " + ($stagedToolFiles -join ", ")) }
if ($stagedSkillDirs.Count -gt 0) { Write-Log ("Staged skill dirs into " + (Join-Path $Target "skills") + ": " + ($stagedSkillDirs -join ", ")) }
if ($skippedPluginFiles.Count -gt 0) { Write-Log ("Skipped existing plugin files: " + ($skippedPluginFiles -join ", ")) }
if ($skippedToolFiles.Count -gt 0) { Write-Log ("Skipped existing tool files: " + ($skippedToolFiles -join ", ")) }
if ($skippedSkillDirs.Count -gt 0) { Write-Log ("Skipped existing skill dirs: " + ($skippedSkillDirs -join ", ")) }

# 3. locate the config file to merge into (opencode.json > opencode.jsonc)
$cfgPath = Join-Path $Target "opencode.json"
$createdConfig = $false
if (-not (Test-Path -LiteralPath $cfgPath)) { New-Item -ItemType File -Path $cfgPath -Force | Out-Null; $createdConfig = $true }
if (Test-Path -LiteralPath (Join-Path $Target "opencode.jsonc")) {
  $cfgPath = Join-Path $Target "opencode.jsonc"
}

# backup
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$cfgPath.aie-backup-$stamp"
if ($createdConfig) {
  $backup = ""
  Write-Log "No pre-existing config to back up; created $cfgPath"
} else {
  Copy-Item -LiteralPath $cfgPath -Destination $backup -Force
  Write-Log "Backed up $cfgPath to $backup"
}

$cfgContent = Get-Content -LiteralPath $cfgPath -Raw
$skippedAgents = @(); $addedAgentKeys = @()
$skippedCmds = @(); $addedCommandKeys = @()
$addedInstructions = @(); $existingInstructions = @()

$ManagedRef = $Managed.Replace("\", "/")

# instructions are added as ABSOLUTE refs into the managed subdir (OpenCode resolves
# instructions relative to the config file, so plain names would miss the subdir)
$ManagedInstructions = @("$ManagedRef/AGENTS.md", "$ManagedRef/INSTRUCTIONS.md")

try {
  $json = $cfgContent | ConvertFrom-Json
  $changed = $false

  # agents
  if (-not $json.agent) { $json | Add-Member -NotePropertyName "agent" -NotePropertyValue ([pscustomobject]@{}) }
  foreach ($k in $AgentKeys) {
    if ($null -ne $json.agent.PSObject.Properties[$k]) { $skippedAgents += $k; continue }
    $prompt = "{file:$ManagedRef/agents/$k.txt}"
    $json.agent | Add-Member -NotePropertyName $k -NotePropertyValue @{
      description = $AgentDescriptions[$k]
      mode = "subagent"
      prompt = $prompt
      tools = @{ read = $true; bash = $true; write = $false; edit = $false }
    }
    $addedAgentKeys += $k; $changed = $true
  }
  # commands
  if (-not $json.command) { $json | Add-Member -NotePropertyName "command" -NotePropertyValue ([pscustomobject]@{}) }
  foreach ($k in $CommandKeys) {
    if ($null -ne $json.command.PSObject.Properties[$k]) { $skippedCmds += $k; continue }
    $tpl = "{file:$ManagedRef/commands/$k.md}`n`n`$ARGUMENTS"
    $json.command | Add-Member -NotePropertyName $k -NotePropertyValue @{
      description = $CommandDescriptions[$k]
      template = $tpl
      agent = $CommandAgents[$k]
      subtask = $true
    }
    $addedCommandKeys += $k; $changed = $true
  }
  # instructions
  if (-not $json.instructions) { $json | Add-Member -NotePropertyName "instructions" -NotePropertyValue @() }
  $existingInstructions = @($json.instructions)
  foreach ($ins in $ManagedInstructions) {
    if ($existingInstructions -notcontains $ins) { $json.instructions = @($json.instructions) + $ins; $addedInstructions += $ins; $changed = $true }
  }

  if ($changed) {
    Set-Content -LiteralPath $cfgPath -Value ($json | ConvertTo-Json -Depth 15) -Encoding UTF8
    Write-Log "Merged config into $cfgPath"
  } else {
    Write-Log "Config already complete; no merge needed in $cfgPath"
  }
} catch {
  # not strict JSON (e.g., opencode.jsonc comments) - record it and let the user merge manually
  Write-Log "WARNING: could not parse $cfgPath as JSON ($($_.Exception.Message))."
  Write-Log "Skipping merge. Add these refs to $cfgPath yourself if desired:"
  Write-Log "  agent/command/instructions entries pointing at $ManagedRef"
}

# 4. write the marker
$markerDoc = @{
  package     = "opencode-agent-harness"
  version     = "1.0.0"
  installedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
  target      = $Target
  managedPath = $Managed
  configPath  = $cfgPath
  backupPath  = $backup
  createdConfig = $createdConfig
  addedAgentKeys    = $addedAgentKeys
  skippedAgentKeys  = $skippedAgents
  addedCommandKeys  = $addedCommandKeys
  skippedCommandKeys = $skippedCmds
  addedInstructions = $addedInstructions
  existingInstructions = $existingInstructions
  stagedPluginFiles = $stagedPluginFiles
  skippedPluginFiles = $skippedPluginFiles
  stagedToolFiles   = $stagedToolFiles
  skippedToolFiles  = $skippedToolFiles
  stagedSkillDirs  = $stagedSkillDirs
  skippedSkillDirs = $skippedSkillDirs
  note = "Skipped keys/files already existed in the target config and were left untouched. Uninstall: run install.ps1 -Uninstall"
} | ConvertTo-Json -Depth 5
Set-Content -LiteralPath $Marker -Value $markerDoc -Encoding UTF8
Write-Log "Marker written to $Marker"

Write-Log "Install complete for target $Target"
Write-Log "Restart OpenCode to load the plugin/agents/commands/skills."
Write-Log ("To reverse: " + $PSCommandPath + " -Uninstall")