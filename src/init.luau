local createActionRegistry = require("@root/createActionRegistry")
local createGateway = require("@root/createGateway")
local types = require("@root/types")

export type Action<Context> = types.Action<Context>
export type ActionResult = types.ActionResult
export type Config = types.Config
export type InputSchema = types.InputSchema

return {
	createActionRegistry = createActionRegistry,
	createGateway = createGateway,
}
