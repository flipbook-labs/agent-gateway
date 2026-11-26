--[[
	Finds the first reason a value cannot be represented as JSON, or nil if it
	can. HttpService:JSONEncode cannot be used for this: it silently encodes
	unsupported values like Instances as null instead of erroring, which is
	exactly the kind of quiet data loss this check exists to surface.

	Returns a problem description rooted at `result`, e.g.
	'result.instance is an Instance'.
]]

local function findProblem(value: unknown, path: string, visiting: { [any]: boolean }): string?
	if value == nil then
		return nil
	end

	local valueType = typeof(value)
	if valueType == "boolean" or valueType == "number" or valueType == "string" then
		return nil
	end
	if valueType ~= "table" then
		return `{path} is {if valueType == "Instance" then "an Instance" else `a {valueType}`}`
	end

	local fields = value :: { [unknown]: unknown }
	if visiting[fields] then
		return `{path} refers back to one of its own ancestors (a cycle)`
	end
	visiting[fields] = true

	local count = 0
	local hasStringKey = false
	local hasNumberKey = false
	for key in fields do
		count += 1
		if type(key) == "string" then
			hasStringKey = true
		elseif type(key) == "number" then
			hasNumberKey = true
		else
			visiting[fields] = nil
			return `{path} has a {typeof(key)} key; keys must be strings or a contiguous 1..n array`
		end
	end

	if hasStringKey and hasNumberKey then
		visiting[fields] = nil
		return `{path} mixes string and number keys; use one or the other`
	end
	if hasNumberKey and count ~= #fields then
		visiting[fields] = nil
		return `{path} is a sparse or non-contiguous array; arrays must have keys 1..n`
	end

	for key, child in fields do
		local childPath = if type(key) == "string" then `{path}.{key}` else `{path}[{tostring(key)}]`
		local problem = findProblem(child, childPath, visiting)
		if problem ~= nil then
			visiting[fields] = nil
			return problem
		end
	end

	visiting[fields] = nil
	return nil
end

local function validateResult(value: unknown): string?
	return findProblem(value, "result", {})
end

return validateResult
