---
name: prompt-engineering
description: Systematic prompt design, testing, and maintenance. Apply when creating, modifying, or reviewing prompts for LLM features.
metadata:
  origin: AI-Engineering
---

# Prompt Engineering Skill

Systematic prompt design, testing, and maintenance. Apply when creating, modifying, or reviewing prompts for LLM features.

## Prompt Engineering Principles

### Clarity
- State the task explicitly
- Define the desired output format
- Specify constraints and boundaries
- Use concrete examples

### Structure
- Use system prompts for role and constraints
- Use user prompts for specific tasks
- Separate context from instructions
- Use delimiters for different content sections

### Robustness
- Handle edge cases in the prompt
- Include error handling instructions
- Define what to do when uncertain
- Prevent prompt injection

## Prompt Design Patterns

### Role-Based
```
You are a [role] specializing in [domain].
Your task is to [action].
Output format: [format]
```

### Chain-of-Thought
```
Think step by step:
1. First, [step 1]
2. Then, [step 2]
3. Finally, [step 3]
```

### Few-Shot
```
Here are examples of correct behavior:

Input: [example 1]
Output: [result 1]

Input: [example 2]
Output: [result 2]

Now handle this:
Input: [actual input]
```

### Constraint-Based
```
Rules:
- Always [required behavior]
- Never [prohibited behavior]
- If [edge case], then [handling]
```

## Prompt Versioning

Every prompt should be:
1. Versioned (v1, v2, etc.)
2. Tracked with change description
3. Linked to evaluation results
4. Tested before deployment

## Prompt Regression Prevention

When modifying a prompt:
1. Document what changed and why
2. Run evaluation dataset against new version
3. Compare results to baseline
4. Investigate any regressions
5. Only deploy if no regressions
6. Update evaluation dataset if new edge cases found

## Anti-Patterns

- Vague instructions ("make it good")
- No output format specification
- Trusting user input without sanitization
- No evaluation before deployment
- No versioning or change tracking
- Prompt injection vulnerabilities
