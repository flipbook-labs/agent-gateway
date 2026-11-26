local types = require("@root/types")

type InputSchema = types.InputSchema

local SUPPORTED_PROPERTY_TYPES = {
	string = true,
	number = true,
	integer = true,
	boolean = true,
	object = true,
	array = true,
}

--[[
	Validates that an action's inputSchema is well-formed, so schema mistakes
	surface when the registry is constructed (plugin load) rather than as
	confusing validation behavior when an agent calls the action.

	Throws on the first problem found.
]]
local function validateInputSchema(actionName: string, inputSchema: InputSchema?)
	if inputSchema == nil then
		return
	end

	if inputSchema.type ~= "object" then
		error(`action "{actionName}": inputSchema.type must be "object", got "{tostring(inputSchema.type)}"`)
	end

	local properties = inputSchema.properties
	if properties ~= nil then
		for propertyName, property in properties do
			if type(property) ~= "table" then
				error(`action "{actionName}": inputSchema property "{propertyName}" must be a table`)
			end
			if not SUPPORTED_PROPERTY_TYPES[property.type] then
				error(
					`action "{actionName}": inputSchema property "{propertyName}" has unsupported type`
						.. ` "{tostring(property.type)}" (supported: string, number, integer, boolean, object, array)`
				)
			end

			local enum = property.enum
			if enum ~= nil then
				if type(enum) ~= "table" or #enum == 0 then
					error(`action "{actionName}": inputSchema property "{propertyName}" enum must be a non-empty array`)
				end
			end
		end
	end

	local required = inputSchema.required
	if required ~= nil then
		for _, requiredName in required do
			if type(requiredName) ~= "string" then
				error(`action "{actionName}": inputSchema.required entries must be strings`)
			end
			if properties == nil or properties[requiredName] == nil then
				error(`action "{actionName}": inputSchema.required names "{requiredName}" which is not in properties`)
			end
		end
	end
end

return validateInputSchema
