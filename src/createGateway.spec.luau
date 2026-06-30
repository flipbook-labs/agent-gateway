local JestGlobals = require("@pkg/JestGlobals")

local createActionRegistry = require("@root/createActionRegistry")
local createGateway = require("@root/createGateway")

local afterEach = JestGlobals.afterEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type Context = {}

local function makeRegistry(actions: { any }?)
	return createActionRegistry({ name = "TestGateway", protocolVersion = 1 }, {} :: Context, actions or {})
end

local function invoke(parent: Instance, name: string, request: any): any
	local bf = parent:FindFirstChild(name) :: BindableFunction
	return bf:Invoke(request)
end

describe("createGateway", function()
	local parent: Folder
	local cleanup: (() -> ())?

	afterEach(function()
		if cleanup then
			cleanup()
			cleanup = nil
		end
		if parent then
			parent:Destroy()
		end
	end)

	local function setup(actions: { any }?, configOverrides: { [string]: any }?)
		parent = Instance.new("Folder")
		local registry = makeRegistry(actions)
		local config = {
			name = "TestGateway",
			protocolVersion = 1,
			parent = parent,
		}
		if configOverrides then
			for k, v in configOverrides do
				(config :: any)[k] = v
			end
		end
		cleanup = createGateway(registry, config)
		return registry
	end

	it("publishes a BindableFunction under the configured parent", function()
		setup()

		local bf = parent:FindFirstChild("TestGateway")
		expect(bf).never.toBeNil()
		expect((bf :: Instance).ClassName).toBe("BindableFunction")
	end)

	it("sets the ProtocolVersion attribute", function()
		setup(nil, { protocolVersion = 7 })

		local bf = parent:FindFirstChild("TestGateway") :: Instance
		expect(bf:GetAttribute("ProtocolVersion")).toBe(7)
	end)

	it("list returns all registered actions", function()
		setup({
			{
				name = "first",
				title = "First",
				description = "An action",
				inputSchema = nil,
				iconName = nil,
				run = function(): any
					return nil
				end,
			},
			{
				name = "second",
				title = "Second",
				description = "Another action",
				inputSchema = nil,
				iconName = nil,
				run = function(): any
					return nil
				end,
			},
		})

		local result = invoke(parent, "TestGateway", { method = "list" })

		expect(result.ok).toBe(true)
		expect(#result.result.actions).toBe(2)
	end)

	it("call dispatches an action", function()
		setup({
			{
				name = "ping",
				title = "Ping",
				description = "Returns pong",
				inputSchema = nil,
				iconName = nil,
				run = function(): any
					return "pong"
				end,
			},
		})

		local result = invoke(parent, "TestGateway", { method = "call", action = "ping" })

		expect(result.ok).toBe(true)
		expect(result.result).toBe("pong")
	end)

	it("returns an error for a non-table request", function()
		setup()

		local result = invoke(parent, "TestGateway", "not a table")

		expect(result.ok).toBe(false)
		expect(result.error).toContain("malformed request")
	end)

	it("returns an error for an unknown method", function()
		setup()

		local result = invoke(parent, "TestGateway", { method = "execute" })

		expect(result.ok).toBe(false)
		expect(result.error).toContain("malformed request")
	end)

	it("returns an error for call without an action name", function()
		setup()

		local result = invoke(parent, "TestGateway", { method = "call" })

		expect(result.ok).toBe(false)
		expect(result.error).toContain("malformed request")
	end)

	it("is idempotent: replaces an existing gateway with the same name", function()
		setup()

		local firstBf = parent:FindFirstChild("TestGateway")

		cleanup = createGateway(makeRegistry(), {
			name = "TestGateway",
			protocolVersion = 2,
			parent = parent,
		})

		local secondBf = parent:FindFirstChild("TestGateway")

		expect(secondBf).never.toBeNil()
		expect(secondBf).never.toBe(firstBf)
		expect((secondBf :: Instance):GetAttribute("ProtocolVersion")).toBe(2)
	end)

	it("cleanup removes the gateway from the parent", function()
		setup()

		expect(parent:FindFirstChild("TestGateway")).never.toBeNil()

		assert(cleanup, "cleanup should be set after setup")
		cleanup()
		cleanup = nil

		expect(parent:FindFirstChild("TestGateway")).toBeNil()
	end)
end)
