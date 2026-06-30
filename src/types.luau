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
	run: (context: Context, params: unknown?) -> unknown,
}

-- ManifestEntry is the serializable subset of Action sent across the gateway
-- boundary: everything except the run function.
export type ManifestEntry = {
	name: string,
	title: string,
	description: string,
	inputSchema: InputSchema?,
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
