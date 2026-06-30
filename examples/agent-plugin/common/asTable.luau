-- Narrows the untyped `params` payload that crosses the gateway's
-- BindableFunction boundary into a string-keyed table, so each action can pull
-- fields out defensively.
local function asTable(params: unknown?): { [string]: unknown }
	if type(params) == "table" then
		return params :: { [string]: unknown }
	end
	return {}
end

return asTable
