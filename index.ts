/**
 * opencode-agent-harness — Plugin entry
 *
 * Published-module parity entry. The local OpenCode setup loads the plugin via
 * `./plugins` in opencode.json, which resolves to ./plugins/index.ts. This root
 * module exports the same plugin function so the package can also be published
 * and imported as a module.
 *
 * @packageDocumentation
 */

// Export the main plugin
// opencode's legacy plugin loader iterates every module export and throws if
// any is not a plugin function, so only the plugin function may be exported.
export { default } from "./plugins/index.js"