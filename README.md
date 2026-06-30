# PluginAgents

[![CI](https://github.com/flipbook-labs/plugin-agents/actions/workflows/ci.yml/badge.svg)](https://github.com/flipbook-labs/plugin-agents/actions/workflows/ci.yml)

Plugin Agents is a Roblox library for exposing Studio plugin actions to in-Studio agents through a small, MCP-inspired gateway.

This repository is in early setup. The initial package will provide:

- A generic actions registry for named, parameterized plugin behaviors
- A single `BindableFunction` gateway for agent discovery and invocation
- A small manifest format inspired by MCP tools, without claiming MCP wire protocol compatibility

## Installation

### Wally

```toml
[dependencies]
PluginAgents = "flipbook-labs/plugin-agents@x.x.x"
```

## Usage

Define your plugin's actions, register them, and stand up a gateway. Actions marked `surfaces = { agent = true }` are discoverable and invokable by in-Studio agents; everything else stays plugin-only.

```lua
local PluginAgents = require(path.to.PluginAgents)

type Context = { plugin: Plugin }

local config: PluginAgents.Config = {
	name = "MyPluginGateway",
	protocolVersion = 1,
}

local context: Context = { plugin = plugin }

local actions: { PluginAgents.Action<Context> } = {
	{
		name = "insertPart",
		title = "Insert Part",
		description = "Insert a new anchored Part into the Workspace.",
		inputSchema = {
			type = "object",
			properties = {
				name = { type = "string", description = "Name for the new Part" },
			},
		},
		surfaces = { agent = true },
		run = function(ctx, params)
			local part = Instance.new("Part")
			part.Anchored = true
			part.Parent = workspace
			return { name = part.Name }
		end,
	},
}

local registry = PluginAgents.createActionRegistry(config, context, actions)
local cleanup = PluginAgents.createGateway(registry, config)

plugin.Unloading:Connect(cleanup)
```

An agent then talks to the gateway `BindableFunction` (parented to `CoreGui` by default):

```lua
local gateway = game:GetService("CoreGui").MyPluginGateway

-- Discover agent-visible actions
gateway:Invoke({ method = "list" })

-- Invoke one
gateway:Invoke({ method = "call", action = "insertPart", params = { name = "AgentPart" } })
```

For a complete, runnable plugin see [`examples/agent-plugin`](examples/agent-plugin).

## License

The contents of this repository are available under the MIT License. For full license text, see [LICENSE](LICENSE).
