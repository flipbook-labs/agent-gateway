local types = require("@root/types")

type Action<Context> = types.Action<Context>
type ActionResult = types.ActionResult
type Config = types.Config
type Manifest = types.Manifest
type ManifestEntry = types.ManifestEntry
type SurfaceName = types.SurfaceName
type Surfaces = types.Surfaces

type ActionRegistry<Context> = {
	actions: { Action<Context> },
	dispatch: (name: string, params: any?, surface: SurfaceName?) -> ActionResult,
	manifest: (surface: SurfaceName?) -> Manifest,
}

local function isVisibleToSurface(surfaces: Surfaces?, surface: SurfaceName?): boolean
	if surface == nil then
		return true
	end
	if surfaces == nil then
		return true
	end
	return surfaces[surface] == true
end

local function createActionRegistry<Context>(
	config: Config,
	context: Context,
	actions: { Action<Context> }
): ActionRegistry<Context>
	-- Snapshot the caller's array so manifest and dispatch always agree,
	-- even if the caller mutates the original table after construction.
	local snapshot: { Action<Context> } = table.move(actions, 1, #actions, 1, {})

	local nameSet: { [string]: boolean } = {}
	for _, action in snapshot do
		if action.name == "" then
			error("action name must not be empty")
		end
		if nameSet[action.name] then
			error(`duplicate action name: "{action.name}"`)
		end
		nameSet[action.name] = true
	end

	local actionMap: { [string]: Action<Context> } = {}
	for _, action in snapshot do
		actionMap[action.name] = action
	end

	local function dispatch(name: string, params: any?, surface: SurfaceName?): ActionResult
		local action = actionMap[name]
		if action == nil then
			return { ok = false, error = `unknown action: {name}` }
		end

		if surface ~= nil and not isVisibleToSurface(action.surfaces, surface) then
			return { ok = false, error = `unknown action: {name}` }
		end

		local ok, value = pcall(action.run, context, params)
		if ok then
			return { ok = true, result = value }
		else
			return { ok = false, error = tostring(value) }
		end
	end

	local function manifest(surface: SurfaceName?): Manifest
		local entries: { ManifestEntry } = {}

		for _, action in snapshot do
			if isVisibleToSurface(action.surfaces, surface) then
				table.insert(entries, {
					name = action.name,
					title = action.title,
					description = action.description,
					inputSchema = action.inputSchema,
					surfaces = action.surfaces,
				})
			end
		end

		return {
			protocolVersion = config.protocolVersion,
			actions = entries,
		}
	end

	return {
		actions = snapshot,
		dispatch = dispatch,
		manifest = manifest,
	}
end

return createActionRegistry
