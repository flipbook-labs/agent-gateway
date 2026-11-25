# Changelog

All notable changes to this project will be documented in this file.


## v0.2.1

Changes 2 · Dependencies 3 · Internal 2

### Changes

1. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-light.png" alt="Tooling" height="18" align="texttop"></picture> Upgrade the Changewrite release action to `v0.7.0` and adopt its `publish-lock` check. ([#14](https://github.com/flipbook-labs/agent-gateway/pull/14))
2. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-release-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-release-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-release-light.png" alt="Release" height="18" align="texttop"></picture> Release automation reads the public Flipbook Backend App Client ID from an organization variable. ([#21](https://github.com/flipbook-labs/agent-gateway/pull/21))

<details>
<summary>Dependencies (3)</summary>

1. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-light.png" alt="Tooling" height="18" align="texttop"></picture> Upgrade FlipbookBatteries `v0.10.1` → `v0.12.0` and Lute `v1.0.1-nightly.20260508` → `v1.0.1-nightly.20260701`. ([#16](https://github.com/flipbook-labs/agent-gateway/pull/16))
2. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-contributing-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-contributing-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-contributing-light.png" alt="Contributing" height="18" align="texttop"></picture> Add AgentSkills `v0.4.0` as a dev dependency so agents can bootstrap the shared skills library. ([#20](https://github.com/flipbook-labs/agent-gateway/pull/20))
3. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-light.png" alt="Tooling" height="18" align="texttop"></picture> Manage the Lute tooling with `pkg.luau`, and ship `src/.config.luau` so AgentGateway keeps its own aliases. ([#24](https://github.com/flipbook-labs/agent-gateway/pull/24))

</details>

<details>
<summary>Internal (2)</summary>

1. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-tooling-light.png" alt="Tooling" height="18" align="texttop"></picture> Upgrade the Changewrite release action to `v0.12.0`. ([#22](https://github.com/flipbook-labs/agent-gateway/pull/22))
2. <picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-release-dark.svg"><source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-release-light.svg"><img src="https://raw.githubusercontent.com/flipbook-labs/agent-gateway/main/.changes/assets/kind-release-light.png" alt="Release" height="18" align="texttop"></picture> Mark each release-notes entry with a chip for the part of AgentGateway it touches, and collapse the Dependencies and Internal sections. ([#23](https://github.com/flipbook-labs/agent-gateway/pull/23))

</details>


## v0.2.0

### Changes

- Removed the `Surface`/`Surfaces` concept entirely. The gateway only ever served the agent surface, so the abstraction added complexity without benefit. The `surfaces` field is gone from `Action` and `ManifestEntry`, and `dispatch`/`manifest` no longer accept a surface filter argument.

- Renamed the package from `PluginAgents` to `AgentGateway` to better reflect its role: it is the gateway that exposes plugin actions to agents, not a package that defines what agents are.

### Features

- Added `createActionRegistry` and `createGateway` — the core public API. Plugins register named actions with input schemas via the registry; the gateway publishes a `BindableFunction` under `CoreGui` so agents can discover (`list`) and invoke (`call`) them over a stable protocol.

- Added an example plugin under `examples/agent-plugin` that registers `insertPart`, `listInstances`, and `renameInstance` actions and wires up the gateway. Added a `.claude/skills/e2e` runbook so agents can validate the full discover-and-invoke round trip from a fresh clone without any prior context.
