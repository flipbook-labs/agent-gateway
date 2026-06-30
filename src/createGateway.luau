local types = require("@root/types")

type ActionResult = types.ActionResult
type Config = types.Config
type Manifest = types.Manifest

type Registry = {
	dispatch: (name: string, params: unknown?) -> ActionResult,
	manifest: () -> Manifest,
}

local function createGateway(registry: Registry, config: Config): () -> ()
	local parent: Instance = config.parent or game:GetService("CoreGui")

	local existing = parent:FindFirstChild(config.name)
	if existing then
		existing:Destroy()
	end

	local gateway = Instance.new("BindableFunction")
	gateway.Name = config.name
	gateway:SetAttribute("ProtocolVersion", config.protocolVersion)

	gateway.OnInvoke = function(request: unknown): ActionResult
		if type(request) ~= "table" then
			return {
				ok = false,
				error = "malformed request: expected a table",
			}
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
				return {
					ok = false,
					error = "malformed request: action must be a string",
				}
			end
			return registry.dispatch(action, fields.params)
		else
			return {
				ok = false,
				error = `malformed request: unknown method "{tostring(fields.method)}"`,
			}
		end
	end

	gateway.Parent = parent

	return function()
		gateway:Destroy()
	end
end

return createGateway
