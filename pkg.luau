return {
	package = {
		name = "AgentGateway",
		version = "0.2.1",
		-- `src/.config.luau` is hidden, so it has to be named to ship.
		files = { "/src/**", "!/src/**/*.spec.luau", "!/src/jest.config.luau", "/src/.config.luau", "/README.md", "/LICENSE" },
		dependencies = {
			["flipbook-batteries"] = {
				rev = "v0.13.1",
				sourceKind = "github",
				source = "https://github.com/flipbook-labs/flipbook-batteries",
			},
			batteries = {
				rev = "v1.0.1-nightly.20261115",
				sourceKind = "github",
				source = "https://github.com/luau-lang/lute",
				target = "batteries",
			},
		},
		dev_dependencies = {
			["agent-skills"] = {
				rev = "v0.9.0",
				sourceKind = "github",
				source = "https://github.com/flipbook-labs/agent-skills",
			},
		},
	},
}
