--!strict
--[[
	Action definitions for the example agent plugin.

	Each action is a PluginAgents.Action<Context>. Actions marked
	`surfaces = { agent = true }` show up in the agent manifest (returned by the
	gateway's `list` method) and can be invoked by an agent. The `openWidget`
	action is `plugin`-only to demonstrate that the gateway hides plugin-surface
	actions from agents.

	`params` crosses the BindableFunction boundary, so it arrives as `unknown` and
	each action narrows it defensively. Errors thrown from `run` are caught by the
	registry and returned to the caller as `{ ok = false, error = ... }`.
]]

local PluginAgents = require(script.Parent.PluginAgents)

local Workspace = game:GetService("Workspace")

export type Context = {
	plugin: Plugin,
}

type Action = PluginAgents.Action<Context>

-- Resolve a slash-separated path like "Workspace/Model/Part" to an instance,
-- treating the first segment as a service off the DataModel. Returns nil if any
-- segment is missing.
local function resolvePath(path: string): Instance?
	local current: Instance = game
	local first = true

	for _, segment in string.split(path, "/") do
		if segment == "" then
			continue
		end

		local nextInstance: Instance? = current:FindFirstChild(segment)

		if nextInstance == nil and first then
			local ok, service = pcall(function()
				return game:GetService(segment :: any)
			end)
			if ok then
				nextInstance = service
			end
		end

		if nextInstance == nil then
			return nil
		end

		current = nextInstance
		first = false
	end

	return current
end

local function asTable(params: unknown?): { [string]: unknown }
	if type(params) == "table" then
		return params :: { [string]: unknown }
	end
	return {}
end

local function create(_context: Context): { Action }
	return {
		{
			name = "insertPart",
			title = "Insert Part",
			description = "Insert a new anchored Part into the Workspace.",
			inputSchema = {
				type = "object",
				properties = {
					name = { type = "string", description = "Name for the new Part (default: AgentPart)" },
				} :: { [string]: unknown },
			},
			surfaces = { agent = true, plugin = true },
			run = function(_ctx, params)
				local options = asTable(params)
				local name = options.name

				local part = Instance.new("Part")
				part.Name = if type(name) == "string" and name ~= "" then name else "AgentPart"
				part.Anchored = true
				part.Parent = Workspace

				return { name = part.Name, path = part:GetFullName() }
			end,
		},

		{
			name = "listInstances",
			title = "List Instances",
			description = "List the children of an instance located by path (defaults to Workspace).",
			inputSchema = {
				type = "object",
				properties = {
					path = { type = "string", description = 'Slash-separated path, e.g. "Workspace/Model"' },
				} :: { [string]: unknown },
			},
			surfaces = { agent = true, plugin = true },
			run = function(_ctx, params)
				local options = asTable(params)
				local path = options.path

				local target: Instance?
				if type(path) == "string" and path ~= "" then
					target = resolvePath(path)
					if target == nil then
						error(`no instance at path: {path}`)
					end
				else
					target = Workspace
				end

				assert(target, "target instance resolved to nil")

				local children = {}
				for _, child in target:GetChildren() do
					table.insert(children, { name = child.Name, className = child.ClassName })
				end

				return { path = target:GetFullName(), children = children }
			end,
		},

		{
			name = "renameInstance",
			title = "Rename Instance",
			description = "Rename an instance located by path.",
			inputSchema = {
				type = "object",
				properties = {
					path = { type = "string", description = "Slash-separated path to the instance" },
					name = { type = "string", description = "New name" },
				} :: { [string]: unknown },
				required = { "path", "name" },
			},
			surfaces = { agent = true, plugin = true },
			run = function(_ctx, params)
				local options = asTable(params)
				local path = options.path
				local name = options.name

				if type(path) ~= "string" or path == "" then
					error("renameInstance requires a non-empty string 'path'")
				end
				if type(name) ~= "string" or name == "" then
					error("renameInstance requires a non-empty string 'name'")
				end

				local target = resolvePath(path)
				if target == nil then
					error(`no instance at path: {path}`)
				end

				local previous = target.Name
				target.Name = name

				return { previous = previous, name = target.Name, path = target:GetFullName() }
			end,
		},

		{
			-- Plugin-surface only: proves the gateway hides this from the agent
			-- manifest and refuses to dispatch it for the agent surface.
			name = "openWidget",
			title = "Open Widget",
			description = "Plugin-only UI action; intentionally hidden from agents.",
			surfaces = { plugin = true },
			run = function()
				return { opened = true }
			end,
		},
	}
end

return {
	create = create,
}
