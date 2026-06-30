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
3. Find the gateway BindableFunction the plugin created.
4. Call `list` to discover the available actions.
5. Decide what to do from there — `call` actions, inspect results, handle errors.

## Prerequisites

- [Rokit](https://github.com/rojo-rbx/rokit) (toolchain manager). Everything else — Rojo, Lute, Darklua, etc. — is pinned in `rokit.toml` and installed by Rokit.
- Roblox Studio.
- A way to run Luau **inside** Studio. Either:
  - the **Roblox Studio MCP** server connected to your client (preferred — it exposes a tool that runs Luau in the open place and returns the result), or
  - the Studio **Command Bar** (View → Command Bar), for running snippets by hand.

  (Last resort, if the MCP can't be attached to your client: drive the `StudioMCP` stdio binary directly with an `execute_luau` call.)

## 1. Bootstrap the toolchain

From the repo root:

```sh
rokit install      # installs pinned tools (rojo, lute, darklua, selene, ...)
lute run install   # installs Loom + Wally dependencies and generates sourcemaps
```

`lute run install` must succeed before any build — it populates `Packages/` and the Loom store the build scripts require.

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
[FlipbookAgentGateway] ready — 4 action(s) registered
```

That line means the plugin ran and the gateway exists. If you don't see it, the plugin didn't load — re-check the install path and that the place is open.

## 4. Locate the gateway

The plugin creates a `BindableFunction` named **`FlipbookAgentGateway`** under `CoreGui` (the default parent). Confirm it exists by running this Luau in Studio (via the Studio MCP run-code tool, or the Command Bar):

```lua
local gateway = game:GetService("CoreGui"):FindFirstChild("FlipbookAgentGateway")
print(gateway, gateway and gateway:GetAttribute("ProtocolVersion"))
```

You should get a `BindableFunction` and a `ProtocolVersion` of `1`. This is the only object an agent needs — everything goes through `gateway:Invoke(request)`.

## 5. Discover actions with `list`

Invoke the gateway with the `list` method to get the manifest of agent-visible actions:

```lua
local gateway = game:GetService("CoreGui").FlipbookAgentGateway
local response = gateway:Invoke({ method = "list" })
print(response)
```

`response` is an `ActionResult`:

```lua
{
    ok = true,
    result = {
        protocolVersion = 1,
        actions = {
            { name = "insertPart",     title = "Insert Part",     description = "...", inputSchema = {...} },
            { name = "listInstances",  title = "List Instances",  description = "...", inputSchema = {...} },
            { name = "renameInstance", title = "Rename Instance", description = "...", inputSchema = {...} },
        },
    },
}
```

Note that **`openWidget` is absent** — it is a `plugin`-surface action, so the gateway hides it from agents. That filtering is part of what you're verifying.

## 6. Call actions and decide what to do

Invoke an action with the `call` method, passing `action` and (optionally) `params`:

```lua
local gateway = game:GetService("CoreGui").FlipbookAgentGateway

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
- **Surface filtering:** calling the hidden action, `gateway:Invoke({ method = "call", action = "openWidget" })`, returns `{ ok = false, error = "unknown action: openWidget" }`.
- **Malformed request:** `gateway:Invoke({})` returns `{ ok = false, error = 'malformed request: unknown method "nil"' }`.

## Request / response reference

Request shape (`GatewayRequest`):

| field    | type                 | when        |
| -------- | -------------------- | ----------- |
| `method` | `"list"` \| `"call"` | always      |
| `action` | `string`             | `call` only |
| `params` | `any?`               | `call` only |

Response shape (`ActionResult`): `{ ok: boolean, result: any?, error: string? }`.

The library API the example uses (`createActionRegistry`, `createGateway`, `Surface`, and the types) is in `src/` and re-exported from `src/init.luau`.
