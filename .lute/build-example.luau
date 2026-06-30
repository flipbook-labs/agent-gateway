local FlipbookBatteries = require("@luaupkg/FlipbookBatteries@v0.10.1")
local cli = require("@batteries/cli")

local project = require("@repo/project")

local dotenv = FlipbookBatteries.dotenv
local mkdir = FlipbookBatteries.mkdir
local rmdir = FlipbookBatteries.rmdir
local run = FlipbookBatteries.run

dotenv()

local args = cli.parser()

args:add("output", "option", {
	help = "Full path to the example plugin rbxm to build",
	aliases = { "o" },
	default = project.EXAMPLE_MODEL_FILENAME,
})

args:parse({ ... })

local output = args:get("output")
assert(typeof(output) == "string", `bad value for output (string expected, got {typeof(output)})`)

-- Build the library first so the example has a compiled PluginAgents to bundle
-- (dist via default.project.json). `lute run build` defaults to the prod channel,
-- which is all the example needs.
run("lute", { "run", "build" })

-- Compile the example the same way as the library: convert its require-by-string
-- to Roblox requires with darklua. The sourcemap maps PluginAgents to the library
-- source so the `@pluginagents` alias resolves to the right instance; darklua reads
-- it from the path configured in .darklua.json.
run("rojo", { "sourcemap", project.ROJO_EXAMPLE_BUILD_PROJECT, "-o", project.DARKLUA_SOURCEMAP_PATH })

rmdir(project.EXAMPLE_BUILD_PATH)
mkdir(project.EXAMPLE_BUILD_PATH)
run("darklua", { "process", project.EXAMPLE_PATH, project.EXAMPLE_BUILD_PATH })

run("rojo", { "build", project.ROJO_EXAMPLE_PROJECT, "-o", output })

print(`Built example plugin to {output}`)
