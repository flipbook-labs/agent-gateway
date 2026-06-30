-- All paths are relative to the root of the repo

return {
	SOURCE_PATH = "src",
	BUILD_PATH = "dist",
	EXAMPLE_PATH = "examples/agent-plugin",
	EXAMPLE_BUILD_PATH = ".build/example",
	PACKAGES_PATH = "Packages",
	LUAU_PACKAGES_PATH = "LuauPackages",
	LUTE_SCRIPTS_PATH = ".lute",

	MODEL_FILENAME = "AgentGateway.rbxm",
	EXAMPLE_MODEL_FILENAME = "AgentPlugin.rbxm",

	SOURCEMAP_PATH = "sourcemap.json",
	DARKLUA_SOURCEMAP_PATH = "sourcemap-darklua.json",
	EXAMPLE_SOURCEMAP_PATH = "sourcemap-example.json",
	BUILD_SOURCEMAP_PATH = "sourcemap-dist.json",

	ROJO_BUILD_PROJECT = "build.project.json",
	ROJO_DEFAULT_PROJECT = "default.project.json",
	ROJO_TESTS_PROJECT = "tests.project.json",
	ROJO_EXAMPLE_PROJECT = "example.project.json",
	ROJO_EXAMPLE_BUILD_PROJECT = "example-build.project.json",

	FOLDERS_TO_LINT = {
		"src",
		".lute",
		"examples",
	},

	ROBLOX_UNIT_TESTING_PLACE_ID = "123506190725771",
	ROBLOX_UNIT_TESTING_UNIVERSE_ID = "6599100156",
}
