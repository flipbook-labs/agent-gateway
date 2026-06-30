local FlipbookBatteries = require("@luaupkg/FlipbookBatteries@v0.10.1")
local cli = require("@batteries/cli")
local fs = require("@std/fs")
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

-- The example plugin consumes PluginAgents through Roblox instance requires, so it
-- needs its own sourcemap. It bundles the built source (dist via the PluginAgents
-- child), so this only runs once a build exists.
local function analyzeExampleSource()
	if not fs.exists(project.BUILD_PATH) then
		print(`skipping example analysis: "{project.BUILD_PATH}" not found (run "lute run build" first)`)
		return
	end

	run("rojo", {
		"sourcemap",
		project.ROJO_EXAMPLE_PROJECT,
		"-o",
		project.EXAMPLE_SOURCEMAP_PATH,
	})

	run("luau-lsp", {
		"analyze",
		`--sourcemap={project.EXAMPLE_SOURCEMAP_PATH}`,
		`--defs={globalDefsPath}`,
		"--settings=./.vscode/settings.json",
		`--ignore="**/_Index/**"`,
		`--ignore="**/jest.config.luau"`,
		"examples",
	})
end

analyzeLuauSource()
analyzeRobloxSource()
analyzeExampleSource()
