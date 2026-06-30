local Surface = require("@root/Surface")
local createActionRegistry = require("@root/createActionRegistry")
local createGateway = require("@root/createGateway")
local types = require("@root/types")

export type Action<Context> = types.Action<Context>
export type ActionResult = types.ActionResult
export type Config = types.Config
export type InputSchema = types.InputSchema
export type Surface = types.Surface
export type Surfaces = types.Surfaces

return {
	Surface = Surface,
	createActionRegistry = createActionRegistry,
	createGateway = createGateway,
}
