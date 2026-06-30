local FlipbookBatteries = require("@luaupkg/FlipbookBatteries@v0.10.1")
local cli = require("@batteries/cli")
local path = require("@std/path")
local system = require("@std/system")

local project = require("@repo/project")

local dotenv = FlipbookBatteries.dotenv
local run = FlipbookBatteries.run

dotenv()

local args = cli.parser()

args:add("include-build", "flag", {
	help = "Include the local build in analysis",
})

args:parse({ ... })

local globalDefsPath = path.join(system.tmpdir(), "globalTypes.d.luau")

run("curl", {
	"-s",
	"-o",
	globalDefsPath,
	"-O",
	"https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/master/scripts/globalTypes.d.lua",
})

local function analyzeLuauSource()
	run("luau-lsp", {
		"analyze",
		`--defs={globalDefsPath}`,
		"--settings=./.vscode/settings.json",
		"--platform=standard",
		"--flag:LuauSolverV2=true",
		project.LUTE_SCRIPTS_PATH,
	})
end

local function analyzeRobloxSource()
	run("rojo", {
		"sourcemap",
		project.ROJO_BUILD_PROJECT,
		"-o",
		project.SOURCEMAP_PATH,
	})

	run("luau-lsp", {
		"analyze",
		`--sourcemap={project.SOURCEMAP_PATH}`,
		`--defs={globalDefsPath}`,
		"--settings=./.vscode/settings.json",
		project.SOURCE_PATH,
	})

	if args:has("include-build") then
		-- The build output uses converted (Roblox-style) requires, so it needs a
		-- sourcemap that maps the package instance to the build tree rather than
		-- to src. Without this, luau-lsp reports "unsupported path" for every
		-- cross-module require in the build.
		run("rojo", {
			"sourcemap",
			project.ROJO_DEFAULT_PROJECT,
			"-o",
			project.BUILD_SOURCEMAP_PATH,
		})

		run("luau-lsp", {
			"analyze",
			`--sourcemap={project.BUILD_SOURCEMAP_PATH}`,
			`--defs={globalDefsPath}`,
			`--ignore="**/_Index/**"`,
			project.BUILD_PATH,
		})
	end
end

-- The example uses require-by-string and consumes AgentGateway as a DataModel
-- instance, so it needs a sourcemap to resolve those requires and the Roblox
-- types. example-build maps AgentGateway to the library source, so unlike a
-- dist-based sourcemap this needs no prior build.
local function analyzeExampleSource()
	run("rojo", {
		"sourcemap",
		project.ROJO_EXAMPLE_BUILD_PROJECT,
		"-o",
		project.EXAMPLE_SOURCEMAP_PATH,
	})

	run("luau-lsp", {
		"analyze",
		`--sourcemap={project.EXAMPLE_SOURCEMAP_PATH}`,
		`--defs={globalDefsPath}`,
		"--settings=./.vscode/settings.json",
		`--ignore="**/_Index/**"`,
		project.EXAMPLE_PATH,
	})
end

analyzeLuauSource()
analyzeRobloxSource()
analyzeExampleSource()
