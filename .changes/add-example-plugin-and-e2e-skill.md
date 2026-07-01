---
bump: minor
category: Features
---

Added an example plugin under `examples/agent-plugin` that registers `insertPart`, `listInstances`, and `renameInstance` actions and wires up the gateway. Added a `.claude/skills/e2e` runbook so agents can validate the full discover-and-invoke round trip from a fresh clone without any prior context.