-- `type` is one of "string", "number", "integer", "boolean", "object", or
-- "array". "object" requires string-keyed tables and "array" requires a
-- contiguous 1..n sequence; an empty table satisfies either (JSON's `[]` and
-- `{}` both decode to the same value). Validation stops at that shape — the
-- element/field types inside a container are the action's to check in run.
export type InputSchemaProperty = {
	type: string,
	description: string?,
	enum: { string | number }?,
	[string]: unknown,
}

export type InputSchema = {
	type: string,
	properties: { [string]: InputSchemaProperty }?,
	required: { string }?,
	[string]: unknown,
}

-- Params have already been validated against the action's inputSchema by the
-- time run is called: required params are present, typed params match their
-- declared type, and unknown params have been rejected. Anything the schema
-- can't express (non-empty strings, instance-at-path, ordering rules) is still
-- the action's job.
export type Action<Context> = {
	name: string,
	title: string,
	description: string,
	inputSchema: InputSchema?,
	run: (context: Context, params: { [string]: unknown }) -> unknown,
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
	name: string,
	description: string?,
	instructions: string?,
	actions: { ManifestEntry },
}

export type ActionResult = {
	ok: boolean,
	result: unknown?,
	error: string?,
}

export type Config = {
	name: string,
	description: string?,
	instructions: string?,
	parent: Instance?,
}

export type GatewayRequest = {
	method: "list" | "call",
	action: string?,
	params: unknown?,
}

return {}
