local JestGlobals = require("@pkg/JestGlobals")

local validateResult = require("@root/validateResult")

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("validateResult", function()
	it("accepts nil, scalars, and plain nested tables", function()
		expect(validateResult(nil)).toBeNil()
		expect(validateResult(true)).toBeNil()
		expect(validateResult(5)).toBeNil()
		expect(validateResult("text")).toBeNil()
		expect(validateResult({})).toBeNil()
		expect(validateResult({ a = 1, b = { c = { "x", "y" } } })).toBeNil()
	end)

	it("rejects an Instance, naming the offending key", function()
		local problem = validateResult({ instance = Instance.new("Folder") })

		expect(problem).toBe("result.instance is an Instance")
	end)

	it("rejects a function nested in an array", function()
		local problem = validateResult({ items = { function() end } })

		expect(problem).toBe("result.items[1] is a function")
	end)

	it("rejects mixed string and number keys", function()
		-- selene: allow(mixed_table)
		local problem = validateResult({ mixed = { "positional", named = true } })

		expect(problem).toContain("result.mixed mixes string and number keys")
	end)

	it("rejects sparse arrays", function()
		local sparse: { [number]: string } = {}
		sparse[1] = "a"
		sparse[3] = "c"
		local problem = validateResult({ list = sparse })

		expect(problem).toContain("result.list is a sparse or non-contiguous array")
	end)

	it("rejects non-string non-number keys", function()
		local problem = validateResult({ [true :: any] = 1 })

		expect(problem).toContain("has a boolean key")
	end)

	it("rejects cycles", function()
		local node: { [string]: unknown } = { name = "a" }
		node.self = node
		local problem = validateResult(node)

		expect(problem).toContain("cycle")
	end)

	it("accepts the same table referenced twice without a cycle", function()
		local shared = { value = 1 }
		local problem = validateResult({ left = shared, right = shared })

		expect(problem).toBeNil()
	end)
end)
