local JestGlobals = require("@pkg/JestGlobals")

local createActionRegistry = require("@root/createActionRegistry")
local createGateway = require("@root/createGateway")
local types = require("@root/types")

local afterEach = JestGlobals.afterEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

type Context = {}
type Action = types.Action<Context>

local function makeRegistry(actions: { Action }?)
	return createActionRegistry({ name = "TestGateway", protocolVersion = 1 }, {} :: Context, actions or {})
end

local function invoke(parent: Instance, name: string, request: unknown): unknown
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

	local function setup(actions: { Action }?)
		parent = Instance.new("Folder")
		cleanup = createGateway(makeRegistry(actions), {
			name = "TestGateway",
			protocolVersion = 1,
			parent = parent,
		})
	end

	it("publishes a BindableFunction under the configured parent", function()
		setup()

		local bf = parent:FindFirstChild("TestGateway")
		expect(bf).never.toBeNil()
		expect((bf :: Instance).ClassName).toBe("BindableFunction")
	end)

	it("sets the ProtocolVersion attribute", function()
		parent = Instance.new("Folder")
		cleanup = createGateway(makeRegistry(), {
			name = "TestGateway",
			protocolVersion = 7,
			parent = parent,
		})

		local bf = parent:FindFirstChild("TestGateway") :: Instance
		expect(bf:GetAttribute("ProtocolVersion")).toBe(7)
	end)

	it("list returns only agent-visible actions", function()
		local forAgents: Action = {
			name = "forAgents",
			title = "For Agents",
			description = "Visible to agents",
			inputSchema = nil,
			iconName = nil,
			surfaces = { agent = true },
			run = function(): unknown
				return nil
			end,
		}
		local pluginOnly: Action = {
			name = "pluginOnly",
			title = "Plugin Only",
			description = "Not for agents",
			inputSchema = nil,
			iconName = nil,
			surfaces = { plugin = true },
			run = function(): unknown
				return nil
			end,
		}
		setup({ forAgents, pluginOnly })

		local result = invoke(parent, "TestGateway", { method = "list" })

		expect((result :: { ok: boolean, result: { actions: { { name: string } } } }).ok).toBe(true)
		expect(#(result :: { ok: boolean, result: { actions: { { name: string } } } }).result.actions).toBe(1)
		expect((result :: { ok: boolean, result: { actions: { { name: string } } } }).result.actions[1].name).toBe(
			"forAgents"
		)
	end)

	it("call dispatches an agent-visible action", function()
		local ping: Action = {
			name = "ping",
			title = "Ping",
			description = "Returns pong",
			inputSchema = nil,
			iconName = nil,
			surfaces = nil,
			run = function(): unknown
				return "pong"
			end,
		}
		setup({ ping })

		local result = invoke(parent, "TestGateway", { method = "call", action = "ping" })

		expect((result :: { ok: boolean, result: unknown }).ok).toBe(true)
		expect((result :: { ok: boolean, result: unknown }).result).toBe("pong")
	end)

	it("call rejects non-agent actions", function()
		local pluginOnly: Action = {
			name = "pluginOnly",
			title = "Plugin Only",
			description = "Not for agents",
			inputSchema = nil,
			iconName = nil,
			surfaces = { plugin = true },
			run = function(): unknown
				return "should not reach"
			end,
		}
		setup({ pluginOnly })

		local result = invoke(parent, "TestGateway", { method = "call", action = "pluginOnly" })

		expect((result :: { ok: boolean, error: string }).ok).toBe(false)
		expect((result :: { ok: boolean, error: string }).error).toBe("unknown action: pluginOnly")
	end)

	it("returns an error for a non-table request", function()
		setup()

		local result = invoke(parent, "TestGateway", "not a table")

		expect((result :: { ok: boolean, error: string }).ok).toBe(false)
		expect((result :: { ok: boolean, error: string }).error).toContain("malformed request")
	end)

	it("returns an error for an unknown method", function()
		setup()

		local result = invoke(parent, "TestGateway", { method = "execute" })

		expect((result :: { ok: boolean, error: string }).ok).toBe(false)
		expect((result :: { ok: boolean, error: string }).error).toContain("malformed request")
	end)

	it("returns an error for call without an action name", function()
		setup()

		local result = invoke(parent, "TestGateway", { method = "call" })

		expect((result :: { ok: boolean, error: string }).ok).toBe(false)
		expect((result :: { ok: boolean, error: string }).error).toContain("malformed request")
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
