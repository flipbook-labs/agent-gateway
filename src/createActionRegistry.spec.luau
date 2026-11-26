local JestGlobals = require("@pkg/JestGlobals")

local constants = require("@root/constants")
local createActionRegistry = require("@root/createActionRegistry")

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type Context = {
	value: string,
}

local defaultConfig = {
	name = "TestGateway",
}

local defaultContext: Context = {
	value = "ctx",
}

local function makeAction(name: string, run: ((ctx: Context, params: any) -> any)?)
	return {
		name = name,
		title = name,
		description = `Action {name}`,
		inputSchema = nil,
		run = run or function(_ctx: Context, _params: any): any
			return nil
		end,
	}
end

describe("createActionRegistry", function()
	describe("dispatch", function()
		it("passes context and params to the action", function()
			local captured: { ctx: Context?, params: any? } = {}

			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("greet", function(ctx, params): any
					captured.ctx = ctx
					captured.params = params
					return "hello"
				end),
			})

			local result = registry.dispatch("greet", { name = "world" })

			expect(result.ok).toBe(true)
			expect(result.result).toBe("hello")
			expect(captured.ctx).toBe(defaultContext)
			expect(captured.params).toEqual({ name = "world" })
		end)

		it("passes an empty table to the action when params are nil", function()
			local captured: { params: any? } = {}

			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("noParams", function(_ctx, params): any
					captured.params = params
					return "done"
				end),
			})

			local result = registry.dispatch("noParams")

			expect(result.ok).toBe(true)
			expect(captured.params).toEqual({})
		end)

		it("returns ok=true with the action return value on success", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("add", function(_ctx, params): any
					return params.a + params.b
				end),
			})

			local result = registry.dispatch("add", { a = 2, b = 3 })

			expect(result.ok).toBe(true)
			expect(result.result).toBe(5)
		end)

		it("returns ok=false with error string when the action throws", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("boom", function(): any
					error("something went wrong")
				end),
			})

			local result = registry.dispatch("boom")

			expect(result.ok).toBe(false)
			expect(typeof(result.error)).toBe("string")
			expect(result.error :: string).toContain("something went wrong")
		end)

		it("lists the available actions for an unknown action name", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("alpha"),
				makeAction("beta"),
			})

			local result = registry.dispatch("missing")

			expect(result.ok).toBe(false)
			expect(result.error :: string).toContain("unknown action: missing")
			expect(result.error :: string).toContain("alpha, beta")
		end)

		it("says so when the gateway has no actions at all", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {})

			local result = registry.dispatch("missing")

			expect(result.ok).toBe(false)
			expect(result.error :: string).toContain("no registered actions")
		end)

		it("returns ok=false when the action result cannot be JSON-encoded", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("leaky", function(): any
					return { instance = Instance.new("Folder") }
				end),
			})

			local result = registry.dispatch("leaky")

			expect(result.ok).toBe(false)
			expect(result.error :: string).toContain("cannot be JSON-encoded")
			expect(result.error :: string).toContain("result.instance is an Instance")
		end)

		it("allows a nil action result", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("nothing", function(): any
					return nil
				end),
			})

			local result = registry.dispatch("nothing")

			expect(result.ok).toBe(true)
			expect(result.result).toBeNil()
		end)
	end)

	describe("params validation", function()
		local function makeSchemaAction(name: string, inputSchema: any, run: ((ctx: Context, params: any) -> any)?)
			local action = makeAction(name, run)
			action.inputSchema = inputSchema
			return action
		end

		local openStory = makeSchemaAction("openStory", {
			type = "object",
			properties = {
				story = { type = "string", description = "Path to a .story ModuleScript" },
				storybook = { type = "string", description = "Optional path to a .storybook ModuleScript" },
			},
			required = { "story" },
		}, function(_ctx, params): any
			return params.story
		end)

		it("rejects a missing required param, quoting the schema", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, { openStory })

			local result = registry.dispatch("openStory", {})

			expect(result.ok).toBe(false)
			expect(result.error :: string).toContain("invalid params for openStory")
			expect(result.error :: string).toContain('missing required param "story"')
			expect(result.error :: string).toContain("Path to a .story ModuleScript")
		end)

		it("rejects a wrongly-typed param", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, { openStory })

			local result = registry.dispatch("openStory", { story = 5 })

			expect(result.ok).toBe(false)
			expect(result.error :: string).toContain('param "story" must be a string, got number')
		end)

		it("rejects an unknown param and lists the valid ones", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, { openStory })

			local result = registry.dispatch("openStory", { story = "a.story", storyPath = "typo" })

			expect(result.ok).toBe(false)
			expect(result.error :: string).toContain('unknown param "storyPath"')
			expect(result.error :: string).toContain("story, storybook")
		end)

		it("rejects non-table params", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, { openStory })

			local result = registry.dispatch("openStory", "a.story")

			expect(result.ok).toBe(false)
			expect(result.error :: string).toContain("params must be a table, got string")
		end)

		it("rejects an enum violation and lists the allowed values", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeSchemaAction("setTheme", {
					type = "object",
					properties = {
						theme = { type = "string", enum = { "system", "dark", "light" } },
					},
					required = { "theme" },
				}),
			})

			local result = registry.dispatch("setTheme", { theme = "neon" })

			expect(result.ok).toBe(false)
			expect(result.error :: string).toContain('"system", "dark", "light"')
			expect(result.error :: string).toContain('got "neon"')
		end)

		it("accepts valid params and does not call run on invalid ones", function()
			local calls = 0
			local action = makeSchemaAction("openStory", openStory.inputSchema, function(_ctx, params): any
				calls += 1
				return params.story
			end)
			local registry = createActionRegistry(defaultConfig, defaultContext, { action })

			local invalid = registry.dispatch("openStory", {})
			expect(invalid.ok).toBe(false)
			expect(calls).toBe(0)

			local valid = registry.dispatch("openStory", { story = "a.story" })
			expect(valid.ok).toBe(true)
			expect(valid.result).toBe("a.story")
			expect(calls).toBe(1)
		end)

		it("passes any table through for an action with no schema", function()
			local captured: { params: any? } = {}
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("free", function(_ctx, params): any
					captured.params = params
					return true
				end),
			})

			local result = registry.dispatch("free", { anything = { goes = true } })

			expect(result.ok).toBe(true)
			expect(captured.params).toEqual({ anything = { goes = true } })
		end)
	end)

	describe("registration validation", function()
		it("throws when an action name is empty", function()
			expect(function()
				createActionRegistry(defaultConfig, defaultContext, {
					makeAction(""),
				})
			end).toThrow("action name must not be empty")
		end)

		it("throws on duplicate action names", function()
			expect(function()
				createActionRegistry(defaultConfig, defaultContext, {
					makeAction("dupe"),
					makeAction("dupe"),
				})
			end).toThrow('duplicate action name: "dupe"')
		end)

		it("throws when an inputSchema is not an object schema", function()
			local action = makeAction("bad")
			action.inputSchema = { type = "string" } :: any

			expect(function()
				createActionRegistry(defaultConfig, defaultContext, { action })
			end).toThrow('inputSchema.type must be "object"')
		end)

		it("throws when required names an undeclared property", function()
			local action = makeAction("bad")
			action.inputSchema = {
				type = "object",
				properties = {
					real = { type = "string" },
				},
				required = { "missing" },
			} :: any

			expect(function()
				createActionRegistry(defaultConfig, defaultContext, { action })
			end).toThrow('required names "missing"')
		end)

		it("throws when a property has an unsupported type", function()
			local action = makeAction("bad")
			action.inputSchema = {
				type = "object",
				properties = {
					weird = { type = "function" },
				},
			} :: any

			expect(function()
				createActionRegistry(defaultConfig, defaultContext, { action })
			end).toThrow('unsupported type "function"')
		end)
	end)

	describe("manifest", function()
		it("includes all registered actions", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("a"),
				makeAction("b"),
			})

			local m = registry.manifest()

			expect(#m.actions).toBe(2)
			expect(m.protocolVersion).toBe(constants.PROTOCOL_VERSION)
		end)

		it("includes the gateway identity and instructions from config", function()
			local config = {
				name = "TestGateway",
				description = "A gateway for tests",
				instructions = "Call the test actions in order.",
			}
			local registry = createActionRegistry(config, defaultContext, {})

			local m = registry.manifest()

			expect(m.name).toBe("TestGateway")
			expect(m.description).toBe("A gateway for tests")
			expect(m.instructions).toBe("Call the test actions in order.")
		end)

		it("includes the correct fields in each manifest entry", function()
			local schema = {
				type = "object",
				properties = {
					value = { type = "string" },
				},
			}
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				{
					name = "myAction",
					title = "My Action",
					description = "Does something",
					inputSchema = schema :: any,
					run = function(): any
						return nil
					end,
				},
			})

			local m = registry.manifest()
			local entry = m.actions[1]

			expect(entry.name).toBe("myAction")
			expect(entry.title).toBe("My Action")
			expect(entry.description).toBe("Does something")
			expect(entry.inputSchema).toEqual(schema)
		end)
	end)
end)
