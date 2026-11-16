local fs = require("@std/fs")
local luau = require("@std/luau")
local process = require("@std/process")

local project = require("@repo/project")

local CONFIG_PATH = ".config.luau"
local LOCKFILE_PATH = "pkg.lock.luau"

-- `lute pkg install` puts each dependency in the Loom store, `~/.loom/store`,
-- under a folder whose name includes hashes of its source and rev. A dependency
-- with a `target` in `pkg.luau` installs only that subfolder, like Lute's
-- `batteries`. The lockfile records where each one landed, but `lute check` and
-- editors read aliases only from `.config.luau`. So after installing, this
-- copies each recorded path into that dependency's alias. Keys are aliases in
-- `.config.luau`, and values are dependency names in `pkg.luau`. A Loom
-- dependency that scripts require needs an entry here to get an alias.
local DEPENDENCY_ALIASES: { [string]: string } = {
	batteries = "Lute",
	["flipbook-batteries"] = "FlipbookBatteries",
}

type Lockfile = {
	dependencies: { [string]: string },
	devDependencies: { [string]: string }?,
	packages: { [string]: { installPath: string } },
}

-- FlipbookBatteries isn't in the Loom store until `lute pkg install` finishes,
-- so this script runs commands with `@std/process` instead of the batteries'
-- `run`.
local function run(command: { string })
	local res = process.run(command, {
		stdio = "inherit",
	})
	assert(res.ok, `{table.concat(command, " ")} failed with exit code {res.exitcode}`)
end

local function getStorePath(lockfile: Lockfile, name: string): string
	local key = lockfile.dependencies[name] or (lockfile.devDependencies and lockfile.devDependencies[name])
	assert(key, `{name} is not a dependency in {LOCKFILE_PATH}`)

	-- The lockfile writes `@pkg/` for the store, and the path of a dependency
	-- without a target ends in `/.`.
	local installPath = lockfile.packages[key].installPath
	return (installPath:gsub("^@pkg/", "~/.loom/store/"):gsub("/%.$", ""))
end

local function installLoomPackages()
	run({ "lute", "pkg", "install" })

	local lockfile: Lockfile = luau.loadModule(LOCKFILE_PATH)
	local config = fs.readFileToString(CONFIG_PATH)

	for alias, name in DEPENDENCY_ALIASES do
		local storePath = getStorePath(lockfile, name)
		-- An alias with a hyphen is written as a `["key"]`, so the pattern allows
		-- the brackets and quotes. The frontier treats `-` as part of a name, so
		-- `batteries` doesn't match the end of `flipbook-batteries`.
		local escapedAlias = alias:gsub("%p", "%%%0")
		local updated, count = config:gsub(`(%f[%w%-]{escapedAlias}"?%]?%s*=%s*")[^"]*(")`, `%1{storePath}%2`)
		assert(count == 1, `Expected one "{alias}" alias in {CONFIG_PATH}, found {count}`)
		config = updated
	end

	fs.writeStringToFile(CONFIG_PATH, config)
	print(`wrote dependency aliases to {CONFIG_PATH}`)
end

local function installWallyPackages()
	run({ "wally", "install" })
	run({ "rojo", "sourcemap", project.ROJO_BUILD_PROJECT, "-o", "sourcemap.json" })
	run({ "wally-package-types", "--sourcemap", "sourcemap.json", "Packages" })
end

installLoomPackages()
installWallyPackages()
