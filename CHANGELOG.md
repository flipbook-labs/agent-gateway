# Changelog

All notable changes to this project will be documented in this file.


## v0.2.0

### Changes

- Removed the `Surface`/`Surfaces` concept entirely. The gateway only ever served the agent surface, so the abstraction added complexity without benefit. The `surfaces` field is gone from `Action` and `ManifestEntry`, and `dispatch`/`manifest` no longer accept a surface filter argument.

- Renamed the package from `PluginAgents` to `AgentGateway` to better reflect its role: it is the gateway that exposes plugin actions to agents, not a package that defines what agents are.

### Features

- Added `createActionRegistry` and `createGateway` — the core public API. Plugins register named actions with input schemas via the registry; the gateway publishes a `BindableFunction` under `CoreGui` so agents can discover (`list`) and invoke (`call`) them over a stable protocol.

- Added an example plugin under `examples/agent-plugin` that registers `insertPart`, `listInstances`, and `renameInstance` actions and wires up the gateway. Added a `.claude/skills/e2e` runbook so agents can validate the full discover-and-invoke round trip from a fresh clone without any prior context.
