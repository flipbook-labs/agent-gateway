--[[
	Example Studio plugin that exposes a few actions to in-Studio agents through
	AgentGateway.

	When this plugin loads it builds an action registry and a gateway. The
	gateway is a BindableFunction named "FlipbookAgentGateway" parented to
	CoreGui. An agent (e.g. via the Studio MCP) discovers and invokes actions by
	calling:

		gateway:Invoke({ method = "list" })
		gateway:Invoke({ method = "call", action = "insertPart", params = { name = "Foo" } })

	See examples/agent-plugin/actions.luau for the action definitions and the
	`e2e` skill (.claude/skills/e2e/SKILL.md) for the full end-to-end test.
]]

local Actions = require("@self/actions")
local AgentGateway = require("@agentgateway")

local config: AgentGateway.Config = {
	name = "FlipbookAgentGateway",
	protocolVersion = 1,
}

local context: Actions.Context = {
	plugin = plugin,
}

local registry = AgentGateway.createActionRegistry(config, context, Actions.create(context))
local cleanup = AgentGateway.createGateway(registry, config)

-- Tear the gateway down when the plugin unloads so a reload doesn't leak a stale
-- BindableFunction (createGateway is also idempotent, but this keeps CoreGui tidy).
plugin.Unloading:Connect(cleanup)

print(`[FlipbookAgentGateway] ready — {#registry.actions} action(s) registered`)
