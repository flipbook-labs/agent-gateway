local types = require("@root/types")

type Action<Context> = types.Action<Context>
type ActionResult = types.ActionResult
type Config = types.Config
type Manifest = types.Manifest
type ManifestEntry = types.ManifestEntry

type ActionRegistry<Context> = {
	actions: { Action<Context> },
	dispatch: (name: string, params: unknown?) -> ActionResult,
	manifest: () -> Manifest,
}

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

	local function dispatch(name: string, params: unknown?): ActionResult
		local action = actionMap[name]
		if action == nil then
			return {
				ok = false,
				error = `unknown action: {name}`,
			}
		end

		local ok, value = pcall(action.run, context, params)
		if ok then
			return {
				ok = true,
				result = value,
			}
		else
			return {
				ok = false,
				error = tostring(value),
			}
		end
	end

	local function manifest(): Manifest
		local entries: { ManifestEntry } = {}

		for _, action in snapshot do
			table.insert(entries, {
				name = action.name,
				title = action.title,
				description = action.description,
				inputSchema = action.inputSchema,
			})
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
