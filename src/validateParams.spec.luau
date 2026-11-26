local JestGlobals = require("@pkg/JestGlobals")

local validateParams = require("@root/validateParams")

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

local SCHEMA = {
	type = "object",
	properties = {
		story = { type = "string", description = "Path to a .story ModuleScript" },
		zoom = { type = "number" },
		count = { type = "integer" },
		enabled = { type = "boolean" },
		controls = { type = "object" },
		tags = { type = "array" },
		screen = { type = "string", enum = { "Home", "Settings", "About", "Logs" } },
	},
	required = { "story" },
} :: any

describe("validateParams", function()
	it("turns nil params into an empty table when there is no schema", function()
		local params, err = validateParams("act", nil, nil)

		expect(err).toBeNil()
		expect(params).toEqual({})
	end)

	it("passes tables through untouched when there is no schema", function()
		local input = { a = 1, b = { c = true } }
		local params, err = validateParams("act", nil, input)

		expect(err).toBeNil()
		expect(params).toBe(input)
	end)

	it("rejects non-table params", function()
		local params, err = validateParams("act", nil, "nope")

		expect(params).toBeNil()
		expect(err).toBe("invalid params for act: params must be a table, got string")
	end)

	it("rejects array-shaped params even with no schema", function()
		local params, err = validateParams("act", nil, { "a", "b" })

		expect(params).toBeNil()
		expect(err :: string).toContain("params must be an object with string keys, got an array")
	end)

	it("rejects nil params when the schema has required properties", function()
		local params, err = validateParams("act", SCHEMA, nil)

		expect(params).toBeNil()
		expect(err :: string).toContain('missing required param "story"')
		expect(err :: string).toContain("Path to a .story ModuleScript")
	end)

	it("accepts params satisfying types, required, and enum", function()
		local input = {
			story = "ReplicatedStorage.Button.story",
			zoom = 1.5,
			count = 3,
			enabled = true,
			controls = { label = "hi" },
			tags = { "a", "b" },
			screen = "Home",
		}
		local params, err = validateParams("act", SCHEMA, input)

		expect(err).toBeNil()
		expect(params).toBe(input)
	end)

	it("rejects a wrongly-typed param with the schema description", function()
		local params, err = validateParams("act", SCHEMA, { story = 5 })

		expect(params).toBeNil()
		expect(err :: string).toContain('param "story" must be a string, got number')
		expect(err :: string).toContain("Path to a .story ModuleScript")
	end)

	it("rejects a non-integer for an integer param", function()
		local _, err = validateParams("act", SCHEMA, { story = "s", count = 1.5 })

		expect(err :: string).toContain('param "count" must be an integer, got number')
	end)

	it("rejects an array for an object param", function()
		local _, err = validateParams("act", SCHEMA, { story = "s", controls = { "a", "b" } })

		expect(err :: string).toContain('param "controls" must be an object, got an array')
	end)

	it("rejects an object for an array param", function()
		local _, err = validateParams("act", SCHEMA, { story = "s", tags = { label = "x" } })

		expect(err :: string).toContain('param "tags" must be an array, got an object')
	end)

	it("accepts an empty table as either an object or an array", function()
		local _, err = validateParams("act", SCHEMA, { story = "s", controls = {}, tags = {} })

		expect(err).toBeNil()
	end)

	it("rejects a table with mixed keys", function()
		-- selene: allow(mixed_table)
		local _, err = validateParams("act", SCHEMA, { story = "s", controls = { "a", named = true } })

		expect(err :: string).toContain('param "controls" must be an object, got a table with mixed keys')
	end)

	it("rejects an enum violation and lists the allowed values", function()
		local _, err = validateParams("act", SCHEMA, { story = "s", screen = "Nope" })

		expect(err :: string).toContain('param "screen" must be one of "Home", "Settings", "About", "Logs", got "Nope"')
	end)

	it("rejects unknown params and lists the valid ones", function()
		local _, err = validateParams("act", SCHEMA, { story = "s", storyPath = "typo" })

		expect(err :: string).toContain('unknown param "storyPath"')
		expect(err :: string).toContain("controls, count, enabled, screen, story, tags, zoom")
	end)

	it("explains when an action takes no params at all", function()
		local _, err = validateParams("act", { type = "object" } :: any, { anything = true })

		expect(err :: string).toContain('unknown param "anything" — this action takes no params')
	end)

	it("reports multiple problems in one message", function()
		local _, err = validateParams("act", SCHEMA, { zoom = "big", extra = 1 })

		expect(err :: string).toContain('missing required param "story"')
		expect(err :: string).toContain('param "zoom" must be a number, got string')
		expect(err :: string).toContain('unknown param "extra"')
	end)
end)
