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

export type ProtocolHelpMethod = {
	name: string,
	request: string,
	description: string,
}

export type ProtocolHelp = {
	protocolVersion: number,
	methods: { ProtocolHelpMethod },
	usage: string,
	responses: {
		success: string,
		failure: string,
	},
	app: string?,
}

export type ActionResult = {
	ok: boolean,
	result: unknown?,
	error: string?,
	help: ProtocolHelp?,
}

export type Config = {
	name: string,
	protocolVersion: number,
	parent: Instance?,
	help: string?,
}

export type GatewayRequest = {
	method: "help" | "list" | "call",
	action: string?,
	params: unknown?,
}

return {}
