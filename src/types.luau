local Surface = require("@root/Surface")

export type Surface = Surface.Surface

export type Surfaces = {
	agent: boolean?,
	plugin: boolean?,
}

export type InputSchema = {
	type: string,
	properties: { [string]: unknown }?,
	required: { string }?,
	[string]: unknown,
}

export type Action<Context> = {
	name: string,
	title: string,
	description: string,
	inputSchema: InputSchema?,
	surfaces: Surfaces?,
	iconName: string?,
	run: (context: Context, params: unknown?) -> unknown,
}

export type ManifestEntry = {
	name: string,
	title: string,
	description: string,
	inputSchema: InputSchema?,
	surfaces: Surfaces?,
}

export type Manifest = {
	protocolVersion: number,
	actions: { ManifestEntry },
}

export type ActionResult = {
	ok: boolean,
	result: unknown?,
	error: string?,
}

export type Config = {
	name: string,
	protocolVersion: number,
	parent: Instance?,
}

export type GatewayRequest = {
	method: "list" | "call",
	action: string?,
	params: unknown?,
}

return {}
