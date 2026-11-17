---
bump: patch
category: Dependencies
kind: tooling
---

Move the Lute tooling from `loom.config.luau` to `pkg.luau` on Lute `v1.0.1-nightly.20261115`, with FlipbookBatteries `v0.13.0` and AgentSkills `v0.7.0`. `lute run install` copies the Loom dependencies into `LuauPackages/`, and path aliases now live in `.config.luau`.
