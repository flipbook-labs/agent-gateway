--[[
	Slash-delimited DataModel path helpers, vendored from flipbook
	(flipbook-labs/flipbook: workspace/flipbook-core/src/Common).

	Unlike `Instance:GetFullName`, which joins names with dots, these use "/" as
	the separator, so a path returned by an action (e.g. "Workspace/AgentBox")
	can be fed straight back into another action that resolves by path.
]]

return {
	getInstanceFromPath = require("@self/getInstanceFromPath"),
	getInstancePath = require("@self/getInstancePath"),
}
