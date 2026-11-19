---
bump: patch
category: Dependencies
kind: tooling
---

Move the Lute tooling from `loom.config.luau` to `pkg.luau` on Lute `v1.0.1-nightly.20261115`, with FlipbookBatteries `v0.13.0` and AgentSkills `v0.7.0`. Path aliases now live in `.config.luau`, which `lute run install` keeps pointed at the installed packages. `pkg.luau` lists the files a Loom package would ship, including `src/.config.luau`, which keeps the package's own `@root` alias with a vendored copy.
