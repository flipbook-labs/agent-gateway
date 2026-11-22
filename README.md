# AgentGateway

AgentGateway lets a Roblox Studio plugin offer its actions to agents. You define each action in Luau, and AgentGateway serves them through one `BindableFunction` built on a small, MCP-inspired protocol, so an agent can list what the plugin can do and call it.

## Install

With Wally:

```toml
[dependencies]
AgentGateway = "flipbook-labs/agent-gateway@0.2.1"
```

With Lute, add this to `pkg.luau` and run `lute pkg install --vendor`:

```luau
["agent-gateway"] = {
	rev = "v0.2.1",
	sourceKind = "github",
	source = "https://github.com/flipbook-labs/agent-gateway",
},
```

## Use

Define an action, register it, and start the gateway from your plugin's script:

```luau
local AgentGateway = require("@pkg/AgentGateway")

type Context = { plugin: Plugin }

local config: AgentGateway.Config = {
	name = "MyPluginGateway",
	protocolVersion = 1,
}

local context: Context = { plugin = plugin }

local actions: { AgentGateway.Action<Context> } = {
	{
		name = "insertPart",
		title = "Insert Part",
		description = "Insert a new anchored Part into the Workspace.",
		run = function(_context, _params)
			local part = Instance.new("Part")
			part.Anchored = true
			part.Parent = workspace
			return { name = part.Name }
		end,
	},
}

local registry = AgentGateway.createActionRegistry(config, context, actions)
local cleanup = AgentGateway.createGateway(registry, config)

plugin.Unloading:Connect(cleanup)
```

An agent then calls the gateway, which the plugin parents to `CoreGui` by default:

```luau
local gateway = game:GetService("CoreGui").MyPluginGateway

gateway:Invoke({ method = "list" })
gateway:Invoke({ method = "call", action = "insertPart" })
```

For a complete plugin, see [`examples/agent-plugin`](examples/agent-plugin).

## Actions

An action takes a `name`, a `title`, a `description`, an optional `inputSchema`, and a `run` function. `run` receives the context you passed to `createActionRegistry` and the `params` the caller sent, which is `nil` when the caller sent none. Its return value becomes the `result`.

`inputSchema` describes the `params` an action takes, using JSON Schema's `type` and `properties` fields. Agents read it from the manifest, but AgentGateway does not validate `params` against it, so `run` should check them:

```luau
inputSchema = {
	type = "object",
	properties = {
		name = { type = "string", description = "Name for the new Part" },
	},
},
```

Names must be non-empty and unique, or `createActionRegistry` raises an error. An error thrown from `run` comes back to the caller as `{ ok = false, error = ... }` and does not stop the gateway. The registry copies the actions array when it is created, so later changes to that table have no effect.

## Protocol

The gateway accepts two methods:

- `list` returns `{ ok = true, result = manifest }`. The manifest holds `protocolVersion` and each action's `name`, `title`, `description`, and `inputSchema`. It leaves out `run`.
- `call` takes an `action` name and optional `params`. It returns `{ ok = true, result = ... }` on success, or `{ ok = false, error = ... }` for an unknown action, a non-string action name, an unknown method, or an error thrown from `run`.

`protocolVersion` comes from the config. The gateway also sets it as a `ProtocolVersion` attribute on the `BindableFunction`.

Set `parent` in the config to place the gateway somewhere other than `CoreGui`. Creating a gateway with a name that already exists under the same parent replaces the old one. The function returned by `createGateway` destroys the gateway.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT.
