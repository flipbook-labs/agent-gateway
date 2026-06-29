local createActionRegistry = require("@root/createActionRegistry")
local createGateway = require("@root/createGateway")
local types = require("@root/types")

export type Action<Context> = types.Action<Context>
export type ActionResult = types.ActionResult
export type Config = types.Config
export type GatewayRequest = types.GatewayRequest
export type InputSchema = types.InputSchema
export type Manifest = types.Manifest
export type ManifestEntry = types.ManifestEntry
export type SurfaceName = types.SurfaceName
export type Surfaces = types.Surfaces

return {
	createActionRegistry = createActionRegistry,
	createGateway = createGateway,
}
