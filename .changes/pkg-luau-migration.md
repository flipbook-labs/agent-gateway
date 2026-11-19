---
bump: patch
category: Dependencies
kind: tooling
---

Move the Lute tooling from `loom.config.luau` to `pkg.luau` on Lute `v1.0.1-nightly.20261117`, with FlipbookBatteries `v0.13.1` and AgentSkills `v0.7.0`. `lute run install` vendors the Lute dependencies into `.lpm/`, which scripts require through one `@lpm` alias in `.config.luau`, the file that replaces `.luaurc`. `pkg.luau` lists the files a Loom package would ship, including `src/.config.luau`, which keeps the package's own `@root` alias with a vendored copy.
