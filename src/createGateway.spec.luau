local CollectionService = game:GetService("CollectionService")

local JestGlobals = require("@pkg/JestGlobals")

local constants = require("@root/constants")
local createActionRegistry = require("@root/createActionRegistry")
local createGateway = require("@root/createGateway")

local afterEach = JestGlobals.afterEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type Context = {}

local function makeRegistry(actions: { any }?, configOverrides: { [string]: any }?)
	local config = {
		name = "TestGateway",
	}
	if configOverrides then
		for k, v in configOverrides do
			(config :: any)[k] = v
		end
	end
	return createActionRegistry(config, {} :: Context, actions or {})
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
		local registry = makeRegistry(actions, configOverrides)
		local config = {
			name = "TestGateway",
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

	it("tags the gateway for discovery", function()
		setup()

		local bf = parent:FindFirstChild("TestGateway") :: Instance
		expect(CollectionService:HasTag(bf, constants.TAG)).toBe(true)
	end)

	it("sets self-describing attributes", function()
		setup(nil, { description = "A test gateway" })

		local bf = parent:FindFirstChild("TestGateway") :: Instance
		expect(bf:GetAttribute("ProtocolVersion")).toBe(constants.PROTOCOL_VERSION)
		expect(bf:GetAttribute("Description")).toBe("A test gateway")
		expect(bf:GetAttribute("Usage")).toBe(constants.USAGE)
	end)

	it("list returns all registered actions", function()
		setup({
			{
				name = "first",
				title = "First",
				description = "An action",
				inputSchema = nil,
				run = function(): any
					return nil
				end,
			},
			{
				name = "second",
				title = "Second",
				description = "Another action",
				inputSchema = nil,
				run = function(): any
					return nil
				end,
			},
		})

		local result = invoke(parent, "TestGateway", { method = "list" })

		expect(result.ok).toBe(true)
		expect(#result.result.actions).toBe(2)
	end)

	it("list includes the gateway identity and instructions", function()
		setup(nil, {
			description = "A test gateway",
			instructions = "Do the test things.",
		})

		local result = invoke(parent, "TestGateway", { method = "list" })

		expect(result.ok).toBe(true)
		expect(result.result.protocolVersion).toBe(constants.PROTOCOL_VERSION)
		expect(result.result.name).toBe("TestGateway")
		expect(result.result.description).toBe("A test gateway")
		expect(result.result.instructions).toBe("Do the test things.")
	end)

	it("call dispatches an action", function()
		setup({
			{
				name = "ping",
				title = "Ping",
				description = "Returns pong",
				inputSchema = nil,
				run = function(): any
					return "pong"
				end,
			},
		})

		local result = invoke(parent, "TestGateway", { method = "call", action = "ping" })

		expect(result.ok).toBe(true)
		expect(result.result).toBe("pong")
	end)

	it("teaches the request grammar on a non-table request", function()
		setup()

		local result = invoke(parent, "TestGateway", "not a table")

		expect(result.ok).toBe(false)
		expect(result.error).toContain("malformed request")
		expect(result.error).toContain('{method = "list"}')
		expect(result.error).toContain('{method = "call", action = "<actionName>", params = {...}}')
	end)

	it("teaches the request grammar on an unknown method", function()
		setup()

		local result = invoke(parent, "TestGateway", { method = "execute" })

		expect(result.ok).toBe(false)
		expect(result.error).toContain('unknown method "execute"')
		expect(result.error).toContain('{method = "list"}')
	end)

	it("teaches the request grammar on an empty request", function()
		setup()

		local result = invoke(parent, "TestGateway", {})

		expect(result.ok).toBe(false)
		expect(result.error).toContain('unknown method "nil"')
		expect(result.error).toContain('{method = "list"}')
	end)

	it("teaches the request grammar on call without an action name", function()
		setup()

		local result = invoke(parent, "TestGateway", { method = "call" })

		expect(result.ok).toBe(false)
		expect(result.error).toContain("call requires an action name")
		expect(result.error).toContain('{method = "list"}')
	end)

	it("is idempotent: replaces an existing gateway with the same name", function()
		setup()

		local firstBf = parent:FindFirstChild("TestGateway")

		cleanup = createGateway(makeRegistry(), {
			name = "TestGateway",
			parent = parent,
		})

		local secondBf = parent:FindFirstChild("TestGateway")

		expect(secondBf).never.toBeNil()
		expect(secondBf).never.toBe(firstBf)
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
