local types = require("@root/types")

type ActionResult = types.ActionResult
type Config = types.Config
type Manifest = types.Manifest
type SurfaceName = types.SurfaceName

type Registry = {
	dispatch: (name: string, params: any?, surface: SurfaceName?) -> ActionResult,
	manifest: (surface: SurfaceName?) -> Manifest,
}

local function createGateway(registry: Registry, config: Config): () -> ()
	local parent: Instance = config.parent or game:GetService("CoreGui")

	local existing = parent:FindFirstChild(config.name)
	if existing then
		existing:Destroy()
	end

	local gateway = Instance.new("BindableFunction")
	gateway.Name = config.name
	gateway:SetAttribute("ProtocolVersion", config.protocolVersion);

	(gateway :: any).OnInvoke = function(request: any): ActionResult
		if type(request) ~= "table" then
			return { ok = false, error = "malformed request: expected a table" }
		end

		local method = request.method

		if method == "list" then
			return { ok = true, result = registry.manifest("agent") }
		elseif method == "call" then
			local action = request.action
			if type(action) ~= "string" then
				return { ok = false, error = "malformed request: action must be a string" }
			end
			return registry.dispatch(action, request.params, "agent")
		else
			return { ok = false, error = `malformed request: unknown method "{tostring(method)}"` }
		end
	end

	gateway.Parent = parent

	return function()
		gateway:Destroy()
	end
end

return createGateway
