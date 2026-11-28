# AgentGateway

AgentGateway lets a Roblox Studio plugin offer its actions to agents. You define each action in Luau, and AgentGateway serves them through one `BindableFunction` built on a small, MCP-inspired protocol, so an agent can list what the plugin can do and call it.

## Install

With Wally:

```toml
[dependencies]
AgentGateway = "flipbook-labs/agent-gateway@0.3.1"
```

With Lute, add this to `pkg.luau` and run `lute pkg install --vendor`:

```luau
["agent-gateway"] = {
	rev = "v0.3.1",
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
	description = "Actions for driving MyPlugin.",
	instructions = "Call insertPart to add a Part to the Workspace.",
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

Every gateway has the `AgentGateway` tag, wherever its plugin parented it, and is named after its config. Several plugins can have one, so an agent picks the gateway it wants by name and calls it:

```luau
local CollectionService = game:GetService("CollectionService")

local gateway
for _, tagged in CollectionService:GetTagged("AgentGateway") do
	if tagged.Name == "MyPluginGateway" then
		gateway = tagged
	end
end

gateway:Invoke({ method = "list" })
gateway:Invoke({ method = "call", action = "insertPart" })
```

For a complete plugin, see [`examples/agent-plugin`](examples/agent-plugin).

## Actions

An action takes a `name`, a `title`, a `description`, an optional `inputSchema`, and a `run` function. `run` receives the context you passed to `createActionRegistry` and the `params` the caller sent, which is an empty table when the caller sent none. Its return value becomes the `result`, and it must be JSON-encodable.

`inputSchema` describes the `params` an action takes, using JSON Schema's `type`, `properties`, and `required` fields, plus `enum` on a property. Agents read it from the manifest, and AgentGateway checks `params` against it before `run`. Anything the schema can't express, such as a path that must resolve, is up to `run`:

```luau
inputSchema = {
	type = "object",
	properties = {
		name = { type = "string", description = "Name for the new Part" },
	},
	required = { "name" },
},
```

Names must be non-empty and unique, or `createActionRegistry` raises an error. An error thrown from `run` comes back to the caller as `{ ok = false, error = ... }` and does not stop the gateway. The registry copies the actions array when it is created, so later changes to that table have no effect.

## Protocol

The gateway accepts two methods:

- `list` returns `{ ok = true, result = manifest }`. The manifest holds `protocolVersion`, the config's `name`, `description`, and `instructions`, and each action's `name`, `title`, `description`, and `inputSchema`. It leaves out `run`.
- `call` takes an `action` name and optional `params`. It returns `{ ok = true, result = ... }` on success, or `{ ok = false, error = ... }` for an unknown action, a non-string action name, an unknown method, `params` that don't match the schema, a result that isn't JSON-encodable, or an error thrown from `run`. The error says how to fix the call.

Every gateway's `BindableFunction` has the `AgentGateway` tag and carries `ProtocolVersion`, `Usage`, and, when the config has one, `Description` attributes. AgentGateway sets the protocol version and exports it with the tag as `PROTOCOL_VERSION` and `TAG`. Use the config's `instructions` to tell agents what to call first and what to wait for.

Set `parent` in the config to place the gateway somewhere other than `CoreGui`. Creating a gateway with a name that already exists under the same parent replaces the old one. The function returned by `createGateway` destroys the gateway.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT.
