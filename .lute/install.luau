local process = require("@std/process")

local project = require("@repo/project")

-- Installs the dependencies in `pkg.luau`. `--vendor` copies each one into a
-- `.lpm/<key>@<rev>` folder, and the `lpm` alias in `.config.luau` points at
-- `.lpm`. When a vendored package requires through `@lpm`, the require uses
-- the `lpm` alias of whichever project vendored it. So any project that
-- vendors such a package has to define the same alias.
-- The following issue tracks removing that requirement:
-- https://github.com/flipbook-labs/flipbook/issues/694
local result = process.run({ "lute", "pkg", "install", "--vendor" }, { stdio = "inherit" })
assert(result.ok, "lute pkg install failed")

-- The Roblox runtime dependencies come from Wally and go in `Packages/`, apart
-- from the Loom dependencies above.
local function run(command: { string })
	local res = process.run(command, { stdio = "inherit" })
	assert(res.ok, `{table.concat(command, " ")} failed with exit code {res.exitcode}`)
end

run({ "wally", "install" })
run({ "rojo", "sourcemap", project.ROJO_BUILD_PROJECT, "-o", "sourcemap.json" })
run({ "wally-package-types", "--sourcemap", "sourcemap.json", "Packages" })
