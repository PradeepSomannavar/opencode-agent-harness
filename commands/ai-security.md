# AI Security Review

Run security review for AI features focusing on prompt injection, tool abuse, MCP security, and agent privilege escalation.

## Instructions

1. Map all trust boundaries (user, model, tools, data, external services)
2. Test for direct prompt injection
3. Test for indirect prompt injection (via retrieved content, tool outputs)
4. Audit tool permissions (least privilege)
5. Verify secret handling
6. Check filesystem access boundaries
7. Review MCP server trustworthiness
8. Test agent privilege escalation paths
9. Output security findings with severity and remediation
