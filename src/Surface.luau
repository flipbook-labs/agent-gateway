export type Surface = "agent" | "plugin"

local Surface = {
	Agent = "agent" :: "agent",
	Plugin = "plugin" :: "plugin",
}

return table.freeze(Surface)
