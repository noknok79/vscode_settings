---
name: subagent-dispatch
description: "Route a request to the correct solution subagent and execute via the orchestrator"
disable-model-invocation: true
argument-hint: "Task to route (feature, tests, docs, security, review, or Confluence publish)"
---
Route and execute the user task with the best specialized solution subagent.

Requirements:
1. Identify task intent and constraints.
2. Choose one best-fit agent.
3. Execute and return concrete artifacts.
4. Keep output concise and action-oriented.

Return:
- Selected agent
- Why it was chosen
- Work completed
- Files/artifacts changed
- Suggested next step
