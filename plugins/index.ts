/**
 * AI Engineering Plugins for OpenCode
 *
 * Hook-based automation for OpenCode sessions: file-edit hygiene (formatting,
 * console.log warnings, TypeScript checks), session lifecycle logging, context
 * compaction, environment injection, and tool registration.
 */

export { AIEHooksPlugin, default } from "./aie-hooks.js"

// Re-export for named imports
export * from "./aie-hooks.js"
