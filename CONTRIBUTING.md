# Contributing

## Setup

Install the pinned toolchain with Rokit, then the Lute packages and Wally dependencies:

```sh
rokit install
lute run install
```

## Checks

```sh
lute run lint
lute run analyze
lute run test
```

Tests are `*.spec.luau` files next to the code they cover.

## Example plugin

`lute run build-example` builds the library and the example plugin into `AgentPlugin.rbxm`. The end-to-end runbook at [`.claude/skills/e2e/SKILL.md`](.claude/skills/e2e/SKILL.md) walks through installing that plugin in Studio and invoking its actions through the gateway.

## Changes and releases

Each user-facing change adds an entry under `.changes/`. See [`.changes/README.md`](.changes/README.md) for the fields. Changewrite assembles the entries into `CHANGELOG.md` and publishes releases.

Agent workflow rules live in [AGENTS.md](AGENTS.md).
