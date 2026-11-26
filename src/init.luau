local constants = require("@root/constants")
local createActionRegistry = require("@root/createActionRegistry")
local createGateway = require("@root/createGateway")
local types = require("@root/types")

export type Action<Context> = types.Action<Context>
export type ActionResult = types.ActionResult
export type Config = types.Config
export type GatewayRequest = types.GatewayRequest
export type InputSchema = types.InputSchema
export type InputSchemaProperty = types.InputSchemaProperty
export type Manifest = types.Manifest
export type ManifestEntry = types.ManifestEntry

return {
	PROTOCOL_VERSION = constants.PROTOCOL_VERSION,
	TAG = constants.TAG,
	createActionRegistry = createActionRegistry,
	createGateway = createGateway,
}
