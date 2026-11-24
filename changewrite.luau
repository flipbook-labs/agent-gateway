return {
	categories = { "Features", "Changes", "Fixes", "Dependencies", "Internal" },
	collapsed = { "Dependencies", "Internal" },
	version = {
		current = "0.2.1",
		mirror = {
			{ file = "pkg.luau" },
			{ file = "wally.toml" },
			{ file = "README.md", pattern = "flipbook%-labs/agent%-gateway@([%d%.]+)" },
			{ file = "README.md", pattern = 'rev = "v([%d%.]+)"' },
		},
	},
	kind = {
		release = { text = "Release", color = "#94606f" },
		actions = { text = "Actions", color = "#5b5bd6" },
		ci = { text = "CI", color = "#75659a" },
		contributing = { text = "Contributing", color = "#5f7f55" },
		docs = { text = "Docs", color = "#8a5a2b" },
		example = { text = "Example", color = "#bc4c00" },
		gateway = { text = "Gateway", color = "#8250df" },
		tooling = { text = "Tooling", color = "#4e8079" },
	},
}
