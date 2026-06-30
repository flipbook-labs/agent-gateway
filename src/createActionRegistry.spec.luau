local JestGlobals = require("@pkg/JestGlobals")

local createActionRegistry = require("@root/createActionRegistry")

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type Context = {
	value: string,
}

local defaultConfig = {
	name = "TestGateway",
	protocolVersion = 1,
}

local defaultContext: Context = {
	value = "ctx",
}

local function makeAction(name: string, run: ((ctx: Context, params: any?) -> any)?)
	return {
		name = name,
		title = name,
		description = `Action {name}`,
		inputSchema = nil,
		run = run or function(_ctx: Context, _params: any?): any
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

		it("returns ok=false for an unknown action name", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {})

			local result = registry.dispatch("missing")

			expect(result.ok).toBe(false)
			expect(result.error).toBe("unknown action: missing")
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
	end)

	describe("manifest", function()
		it("includes all registered actions", function()
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				makeAction("a"),
				makeAction("b"),
			})

			local m = registry.manifest()

			expect(#m.actions).toBe(2)
			expect(m.protocolVersion).toBe(1)
		end)

		it("includes protocolVersion from config", function()
			local config = {
				name = "gw",
				protocolVersion = 42,
			}
			local registry = createActionRegistry(config, defaultContext, {})

			local m = registry.manifest()

			expect(m.protocolVersion).toBe(42)
		end)

		it("includes the correct fields in each manifest entry", function()
			local schema = { type = "object" }
			local registry = createActionRegistry(defaultConfig, defaultContext, {
				{
					name = "myAction",
					title = "My Action",
					description = "Does something",
					inputSchema = schema,
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
