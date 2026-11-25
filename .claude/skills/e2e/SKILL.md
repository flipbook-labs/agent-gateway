---
name: e2e
description: Run the AgentGateway end-to-end test. Use this skill to validate AgentGateway in isolation — build the example Studio plugin, install it, then discover and invoke its actions through the gateway from inside Studio. Use it whenever you want to confirm the agent↔plugin round trip works from a fresh clone, or are asked to "run the e2e test" / "test the example plugin".
---

# End-to-end test for AgentGateway

Take AgentGateway from a fresh clone to a working agent↔plugin round trip: build the example Studio plugin, install it, then discover and invoke its actions through the gateway from inside Studio. Work through the steps below in order. All paths are relative to the repository root.

## What you are testing

AgentGateway exposes a plugin's actions to in-Studio agents through a single [`BindableFunction`](https://create.roblox.com/docs/reference/engine/classes/BindableFunction) gateway. The example plugin in `examples/agent-plugin` registers a few actions and stands up that gateway. The end-to-end test is:

1. Build and install the example plugin.
2. Open a place in Studio so the plugin loads.
3. Discover the gateway BindableFunction by its CollectionService tag.
4. Call `list` to discover the available actions.
5. Decide what to do from there — `call` actions, inspect results, handle errors.

## Prerequisites

- [Rokit](https://github.com/rojo-rbx/rokit) (toolchain manager). Everything else — Rojo, Lute, Darklua, etc. — is pinned in `rokit.toml` and installed by Rokit.
- Roblox Studio.
- A way to run Luau **inside** Studio — see the shared `agent-gateway/use-agent-gateway` skill for Studio MCP setup. The Studio Command Bar (View → Command Bar) works for running snippets by hand.

## 1. Bootstrap the toolchain

From the repo root:

```sh
rokit install      # installs pinned tools (rojo, lute, darklua, selene, ...)
lute run install   # installs Lute packages + Wally dependencies and generates sourcemaps
```

`lute run install` must succeed before any build — it populates `Packages/` and the `.lpm/` folder the build scripts require.

## 2. Build the example plugin

```sh
lute run build-example
```

This first builds the AgentGateway source into `dist/`, then builds the example into `AgentPlugin.rbxm` at the repo root. The task accepts an optional `--output <path>` flag (default `AgentPlugin.rbxm`).

The built model is a single `Script` named `AgentPlugin` with the AgentGateway library nested inside it, so it is fully self-contained.

> **Steps 3–6 require Roblox Studio.** If you only need to confirm the package builds, stop here — steps 1–2 above are the full headless path.

## 3. Install the plugin into Studio

Install `AgentPlugin.rbxm` as a local plugin by copying it into Studio's plugins folder:

- **macOS:** `~/Documents/Roblox/Plugins/AgentPlugin.rbxm`
- **Windows:** `%LOCALAPPDATA%\Roblox\Plugins\AgentPlugin.rbxm`

Alternatively, build it straight into the plugins folder by passing that path as the output, e.g. on macOS:

```sh
lute run build-example --output ~/Documents/Roblox/Plugins/AgentPlugin.rbxm
```

Then open Roblox Studio with any place (a Baseplate is fine). On load you should see this in the Output window:

```
[ExampleAgentGateway] ready — 3 action(s) registered
```

That line means the plugin ran and the gateway exists. If you don't see it, the plugin didn't load — re-check the install path and that the place is open.

## 4. Discover the gateway

Every gateway BindableFunction carries the `AgentGateway` CollectionService tag, so this one convention finds them all — no plugin-specific names or locations needed. Run this Luau in Studio (via the Studio MCP run-code tool, or the Command Bar):

```lua
local CollectionService = game:GetService("CollectionService")

for _, gateway in CollectionService:GetTagged("AgentGateway") do
	print(
		gateway:GetFullName(),
		gateway:GetAttribute("ProtocolVersion"),
		gateway:GetAttribute("Description")
	)
end
```

You should see one `BindableFunction` named **`ExampleAgentGateway`** under `CoreGui`, with a `ProtocolVersion` of `2` and the example plugin's description. The instance also carries a `Usage` attribute with a one-line protocol summary. This is the only object an agent needs — everything goes through `gateway:Invoke(request)`.

## 5. Discover actions with `list`

Invoke the gateway with the `list` method to get the manifest — the gateway's identity, agent instructions, and available actions:

```lua
local CollectionService = game:GetService("CollectionService")
local gateway = CollectionService:GetTagged("AgentGateway")[1]
local response = gateway:Invoke({ method = "list" })
print(response)
```

`response` is an `ActionResult`:

```lua
{
    ok = true,
    result = {
        protocolVersion = 2,
        name = "ExampleAgentGateway",
        description = "Example plugin actions for manipulating Instances in the open place.",
        instructions = "Insert a Part with insertPart, ...",
        actions = {
            { name = "insertPart",     title = "Insert Part",     description = "...", inputSchema = {...} },
            { name = "listInstances",  title = "List Instances",  description = "...", inputSchema = {...} },
            { name = "renameInstance", title = "Rename Instance", description = "...", inputSchema = {...} },
        },
    },
}
```

## 6. Call actions and decide what to do

Invoke an action with the `call` method, passing `action` and (optionally) `params`:

```lua
local gateway = game:GetService("CoreGui").ExampleAgentGateway

-- Insert a Part
gateway:Invoke({ method = "call", action = "insertPart", params = { name = "AgentBox" } })
-- -> { ok = true, result = { name = "AgentBox", path = "Workspace/AgentBox" } }

-- Confirm it landed
gateway:Invoke({ method = "call", action = "listInstances", params = { path = "Workspace" } })
-- -> { ok = true, result = { path = "Workspace", children = { { name = "AgentBox", className = "Part" }, ... } } }

-- Rename it
gateway:Invoke({ method = "call", action = "renameInstance", params = { path = "Workspace/AgentBox", name = "Renamed" } })
-- -> { ok = true, result = { previous = "AgentBox", name = "Renamed", path = "Workspace/Renamed" } }
```

From here, behave like the agent: read each `result`, pick the next action from the manifest, and verify the effect (e.g. the new Part is visible in the Explorer).

### Things worth verifying

- **Success path:** `insertPart` creates a Part you can see in the Explorer.
- **Error path:** a bad path returns `{ ok = false, error = "no instance at path: ..." }` rather than throwing — e.g. `gateway:Invoke({ method = "call", action = "renameInstance", params = { path = "Workspace/Nope", name = "x" } })`.
- **Unknown action:** calling a name that isn't registered, `gateway:Invoke({ method = "call", action = "nope" })`, returns `ok = false` with an error that lists the available actions.
- **Params validation:** the registry validates params against each action's `inputSchema` before the action runs. All of these return `ok = false` with an error that quotes the schema:
  - missing required param: `gateway:Invoke({ method = "call", action = "renameInstance", params = { path = "Workspace/Nope" } })` → `invalid params for renameInstance: missing required param "name" (string) — New name`
  - wrong type: `params = { path = 5, name = "x" }` → `... param "path" must be a string, got number ...`
  - unknown param (typo): `params = { path = "Workspace/X", name = "y", nmae = "z" }` → `... unknown param "nmae" — valid params: name, path`
- **Malformed request:** `gateway:Invoke({})` returns `ok = false` with an error that teaches the request grammar (`Expected {method = "list"} ... or {method = "call", action = "<actionName>", params = {...}} ...`).

## Request / response reference

Request shape (`GatewayRequest`):

| field    | type                 | when        |
| -------- | -------------------- | ----------- |
| `method` | `"list"` \| `"call"` | always      |
| `action` | `string`             | `call` only |
| `params` | `table?`             | `call` only |

Response shape (`ActionResult`): `{ ok: boolean, result: any?, error: string? }`.

Action results must be JSON-encodable; the registry converts non-encodable results (Instances, mixed-key tables) into an `ok = false` error blaming the action.

The library API the example uses (`createActionRegistry`, `createGateway`, the `TAG`/`PROTOCOL_VERSION` constants, and the types) is in `src/` and re-exported from `src/init.luau`.
