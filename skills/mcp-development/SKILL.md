---
name: mcp-development
description: MCP (Model Context Protocol) server and tool development. Apply when building, reviewing, or integrating MCP servers.
metadata:
  origin: AI-Engineering
---

# MCP Development Skill

MCP (Model Context Protocol) server and tool development. Apply when building, reviewing, or integrating MCP servers.

## MCP Server Design Principles

### Least Privilege
- Expose only necessary tools
- Restrict file system access to project scope
- Limit network access to required endpoints
- Require explicit user consent for sensitive operations

### Input Validation
- Validate all tool arguments against schema
- Reject unexpected parameters
- Sanitize string inputs
- Validate file paths (prevent traversal)
- Check numeric bounds

### Output Validation
- Validate tool outputs before returning to agent
- Truncate oversized outputs
- Filter sensitive data from responses
- Ensure consistent response format

### Authentication & Authorization
- Use proper credential management
- Never hardcode API keys or tokens
- Implement token refresh for long-running sessions
- Log authentication events

### Error Handling
- Return structured error responses
- Don't leak internal details in errors
- Provide actionable error messages
- Handle timeouts gracefully

### Transport Security
- Use TLS for remote MCP servers
- Verify server certificates
- Use Unix sockets for local servers
- Never send secrets over unencrypted channels

## MCP Server Template

```typescript
// Minimal MCP server structure
const server = new McpServer({
  name: "my-server",
  version: "1.0.0",
});

server.tool(
  "tool_name",
  { /* schema */ },
  async (args) => {
    // Validate inputs
    // Execute operation
    // Validate outputs
    // Return result
  }
);
```

## MCP Security Checklist

- [ ] Tool permissions follow least-privilege
- [ ] All inputs validated
- [ ] All outputs sanitized
- [ ] Secrets handled securely
- [ ] Transport is encrypted (TLS)
- [ ] Authentication is enforced
- [ ] Error messages don't leak internals
- [ ] Tool calls are logged for auditability
- [ ] Timeouts configured
- [ ] Untrusted content filtered

## Anti-Patterns

- Exposing full filesystem access
- Hardcoding API keys
- Not validating tool arguments
- Returning raw database queries in errors
- Using unencrypted transport
- Trusting MCP server outputs without validation
