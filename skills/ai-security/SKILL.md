---
name: ai-security
description: Security considerations specific to AI/ML/LLM systems. Goes beyond traditional application security.
metadata:
  origin: AI-Engineering
---

# AI Security Skill

Security considerations specific to AI/ML/LLM systems. Goes beyond traditional application security.

## AI-Specific Threat Model

### Prompt Injection

| Type | Description | Mitigation |
|------|-------------|------------|
| Direct injection | User input in prompt | Input sanitization, instruction hierarchy |
| Indirect injection | Injected via retrieved content, tool outputs | Content filtering, trust boundaries |
| Multi-turn injection | Gradual manipulation across conversation | Session-level guardrails |

### Tool Abuse

| Risk | Description | Mitigation |
|------|-------------|------------|
| Excessive permissions | Agent accesses more than needed | Least-privilege tool config |
| Data exfiltration | Agent sends data to unauthorized endpoint | Network restrictions, output filtering |
| Unsafe shell commands | Agent executes dangerous commands | Command allowlisting, sandboxing |
| Filesystem escape | Agent reads/writes outside scope | Path restrictions, chroot |

### MCP Security

| Risk | Description | Mitigation |
|------|-------------|------------|
| Untrusted MCP server | Malicious or compromised server | Verify source, sandbox |
| Excessive tool scope | MCP server exposes dangerous tools | Tool filtering, permissions |
| Secret leakage | Secrets passed to MCP server | Never log secrets, minimal exposure |
| Transport security | Unencrypted communication | TLS required for remote MCP |

### Agent Privilege Escalation

| Risk | Description | Mitigation |
|------|-------------|------------|
| Self-modification | Agent modifies its own rules | Immutable core rules |
| Permission escalation | Agent gains unauthorized tool access | Permission audit trail |
| Tool chain abuse | Agent chains tools for unintended purpose | Tool call logging, anomaly detection |

## Security Checklist for AI Systems

### Before Implementation
- [ ] Threat model documented
- [ ] Trust boundaries defined
- [ ] Tool permissions audited
- [ ] Secret handling plan established

### During Implementation
- [ ] Input validation at system boundaries
- [ ] Output sanitization before display
- [ ] Tool arguments validated
- [ ] Secrets never logged or exposed to model
- [ ] Agent permissions follow least-privilege

### Before Deployment
- [ ] Prompt injection testing completed
- [ ] Tool abuse scenarios tested
- [ ] MCP server trust verified
- [ ] Permission escalation paths closed
- [ ] Audit logging enabled
- [ ] Secret rotation plan in place

## Testing for AI Security

### Prompt Injection Tests
```
Test direct injection: "Ignore previous instructions and..."
Test indirect injection: Include malicious instructions in documents
Test multi-turn: Gradually escalate requests across turns
```

### Tool Abuse Tests
```
Test path traversal: Agent tries to read files outside scope
Test command injection: Agent executes shell with user input
Test data exfiltration: Agent attempts to send data externally
```

### Permission Tests
```
Test tool boundary: Agent tries to use unavailable tools
Test scope creep: Agent requests increasingly powerful access
Test self-modification: Agent attempts to change its own rules
```
