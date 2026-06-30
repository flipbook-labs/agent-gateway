local FlipbookBatteries = require("@luaupkg/FlipbookBatteries@v0.10.1")
local cli = require("@batteries/cli")

local project = require("@repo/project")

local dotenv = FlipbookBatteries.dotenv
local run = FlipbookBatteries.run

dotenv()

local args = cli.parser()

args:add("channel", "option", {
	help = "channel to build the bundled PluginAgents source for",
	aliases = { "c" },
	default = "dev",
})
args:add("output", "option", {
	help = "Full path to the example plugin rbxm to build",
	aliases = { "o" },
	default = project.EXAMPLE_MODEL_FILENAME,
})

args:parse({ ... })

local channel = args:get("channel")
assert(channel == "dev" or channel == "prod", `bad value for channel (must be one of "dev" or "prod", got "{channel}")`)

local output = args:get("output")
assert(typeof(output) == "string", `bad value for output (string expected, got {typeof(output)})`)

-- The example bundles the built PluginAgents source (dist via default.project.json),
-- so produce that first, then build the standalone plugin model.
run("lute", { "run", "build", "--channel", channel })
run("rojo", { "build", project.ROJO_EXAMPLE_PROJECT, "-o", output })

print(`Built example plugin to {output}`)
