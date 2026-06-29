export type SurfaceName = "agent" | "plugin"

export type Surfaces = {
	agent: boolean?,
	plugin: boolean?,
}

export type InputSchema = {
	type: string,
	properties: { [string]: any }?,
	required: { string }?,
	[string]: any,
}

export type Action<Context> = {
	name: string,
	title: string,
	description: string,
	inputSchema: InputSchema?,
	surfaces: Surfaces?,
	iconName: string?,
	run: (context: Context, params: any?) -> any,
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
	result: any?,
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
	params: any?,
}

return {}
