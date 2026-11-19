# AgentGateway agent guide

AgentGateway is a Roblox library for defining the actions an agent can perform with a plugin in Studio, exposed through a small MCP-inspired gateway. The library lives in `src/` (re-exported from `src/init.luau`), and a runnable example plugin lives in `examples/agent-plugin`. It is written in Luau and built with Lute. This file is the entry point for any agent working in the repo. It routes you to the shared skills library and the repo's own setup.

## Mandatory first steps

Complete every step below before you write any code, tests, changelog entries, or PR prose. This is a gate, and it does not depend on how you classify your task.

1. Install the toolchain and dependencies:

   ```sh
   rokit install && lute run install
   ```

   `rokit install` puts `lute`, `luau-lsp`, `stylua`, and `selene` on PATH. `lute run install` copies the Loom dependencies declared in [`pkg.luau`](pkg.luau) into `.lpm/<key>@<rev>` folders, which scripts require through the `@lpm` alias in [`.config.luau`](.config.luau), and installs the Wally runtime dependencies into `Packages/`. The shared skills library is a dev dependency, so it lands in `.lpm/` for you to read but is not shipped with the package. Without this step the skills are not on disk.

2. Find the skills folder: it's `.lpm/agent-skills@<rev>`, where `<rev>` is the `agent-skills` rev in [`pkg.luau`](pkg.luau). Use that path wherever `<skills>` appears below.

3. Read the routing index at `<skills>/AGENTS.md` in full. Its **Project Skills** section lists every skill with a trigger-rich one-liner, so you know what exists before you start. This read is unconditional.

Deep reads of individual `<skills>/src/<scope>/<name>/SKILL.md` files stay on demand: when a task matches a trigger from the index, read that skill before doing the work it covers. Reading the index up front is what lets those triggers fire.

Reading a skill once does not mean you applied it when you wrote the code hours later. When you take a pass over a change and before you call a task done, follow the `org/review-pass` skill: it maps the diff to the skills that govern each file, has you re-open them at that point, runs the writing-style and code-comments critic passes over what you generated, and catches skill drift to feed back (see below).

## Forward this file to subagents

The Task tool spawns subagents in a fresh context that does not include this guide, so they never see the gate unless you hand it to them. Whenever you delegate to a subagent, you MUST include in its prompt:

1. The mandatory first steps above (the bootstrap command and the index read).
2. The concrete resolved path(s) to the specific `SKILL.md` files relevant to its task.

Never assume a subagent will discover the skills on its own.

## Keeping skills current

Skills are living documents. When your work here contradicts a skill (a renamed symbol, a changed value, a fixed bug it still calls known), fix it in the agent-skills repo with a `.changes/` entry in the same effort. The fix reaches this repo on its next `rev` bump. The `org/review-pass` skill folds this check into closing out a task, so it fires without you having to remember it.

## Repo specifics

- Toolchain is managed with [Rokit](https://github.com/rojo-rbx/rokit). Run `rokit install` once to get `lute`, `luau-lsp`, `stylua`, and `selene` on PATH.
- `lute run --list` shows the available scripts: `install`, `build` (`--channel dev`/`prod`), `build-example`, `lint`, `analyze`, and `test`.
- Tests are `*.spec.luau` files alongside the code they cover. Run the suite with `lute run test`.
- A repo-local end-to-end runbook lives at [`.claude/skills/e2e/SKILL.md`](.claude/skills/e2e/SKILL.md): build the example Studio plugin, install it, then discover and invoke its actions through the gateway from inside Studio. Unlike the shared library, this one sits under `.claude/skills/`, so the Skill tool surfaces it directly. The shared library also carries `agent-gateway/use-agent-gateway`, which covers driving a gateway over the Studio MCP server.
- Releases are handled by the [Changewrite](https://github.com/flipbook-labs/changewrite) action. Unreleased entries live as partials in [`.changes/`](.changes) and are assembled into [`CHANGELOG.md`](CHANGELOG.md) at release time. Add a `.changes/` entry for any user-facing change.
