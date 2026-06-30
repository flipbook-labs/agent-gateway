# AGENTS.md

AgentGateway exposes a plugin's actions to in-Studio agents through a single gateway. The library lives in `src/` (re-exported from `src/init.luau`); a runnable example plugin lives in `examples/agent-plugin`.

## Skills

Task-specific runbooks live as skills under `.claude/skills/<name>/SKILL.md`. Each skill's frontmatter `description` says when to use it. To use one, read its `SKILL.md` and follow the steps.

Available skills:

- **`e2e`** (`.claude/skills/e2e/SKILL.md`) — end-to-end test: build the example Studio plugin, install it, then discover and invoke its actions through the gateway from inside Studio.
