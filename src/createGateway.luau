local types = require("@root/types")

type ActionResult = types.ActionResult
type Config = types.Config
type Manifest = types.Manifest
type ProtocolHelp = types.ProtocolHelp

type Registry = {
	dispatch: (name: string, params: unknown?) -> ActionResult,
	manifest: () -> Manifest,
}

local function buildHelp(config: Config): ProtocolHelp
	local help: ProtocolHelp = {
		protocolVersion = config.protocolVersion,
		methods = {
			{
				name = "help",
				request = '{ method = "help" }',
				description = "Return AgentGateway protocol usage help.",
			},
			{
				name = "list",
				request = '{ method = "list" }',
				description = "Return available actions, descriptions, and input schemas. This is the source of truth for callable actions.",
			},
			{
				name = "call",
				request = '{ method = "call", action = "actionName", params = { ... } }',
				description = "Run a named action. Params are action-specific and should match the input schema returned by list.",
			},
		},
		usage = 'Use { method = "list" } to discover actions, then invoke one with { method = "call", action = "actionName", params = { ... } }.',
		responses = {
			success = "{ ok = true, result = ... }",
			failure = "{ ok = false, error = ... }",
		},
	}

	if config.help ~= nil then
		help.app = config.help
	end

	return help
end

local function createGateway(registry: Registry, config: Config): () -> ()
	local parent: Instance = config.parent or game:GetService("CoreGui")
	local protocolHelp = buildHelp(config)

	local function malformed(errorMessage: string): ActionResult
		return {
			ok = false,
			error = errorMessage,
			help = protocolHelp,
		}
	end

	local existing = parent:FindFirstChild(config.name)
	if existing then
		existing:Destroy()
	end

	local gateway = Instance.new("BindableFunction")
	gateway.Name = config.name
	gateway:SetAttribute("ProtocolVersion", config.protocolVersion)

	gateway.OnInvoke = function(request: unknown): ActionResult
		if type(request) ~= "table" then
			return malformed("malformed request: expected a table")
		end

		-- The request crosses a BindableFunction boundary, so its shape is
		-- untrusted. Treat it as a bag of unknown fields and narrow each one.
		local fields = request :: { [string]: unknown }

		if fields.method == "list" then
			return {
				ok = true,
				result = registry.manifest(),
			}
		elseif fields.method == "call" then
			local action = fields.action
			if type(action) ~= "string" then
				return malformed("malformed request: action must be a string")
			end
			return registry.dispatch(action, fields.params)
		elseif fields.method == "help" then
			return {
				ok = true,
				result = protocolHelp,
			}
		else
			return malformed(`malformed request: unknown method "{tostring(fields.method)}"`)
		end
	end

	gateway.Parent = parent

	return function()
		gateway:Destroy()
	end
end

return createGateway
