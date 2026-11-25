-- The protocol version is owned by this library, not by consumers: it
-- describes the request/response contract implemented in createGateway and
-- createActionRegistry, and bumps when that contract changes.
--
-- Version history:
--   1 — list/call, no params validation, terse errors
--   2 — manifest carries name/description/instructions, params validated
--       against inputSchema, discovery tag + attributes, teaching errors
local PROTOCOL_VERSION = 2

-- Every gateway BindableFunction is tagged with this CollectionService tag.
-- Knowing this one convention — from a skill, repo instructions, or a prompt —
-- is enough to find every gateway in a place, whatever it's named or parented
-- to and whichever plugin created it:
--
--   game:GetService("CollectionService"):GetTagged("AgentGateway")
local TAG = "AgentGateway"

-- The two request forms, written once so the "Usage" attribute and the error
-- grammar quote them identically. Change the wording or spacing here, not in
-- the two prose strings below. The README and the shared use-agent-gateway skill
-- in flipbook-labs/agent-skills also quote them, so update those by hand.
local LIST_FORM = '{method = "list"}'
local CALL_FORM = '{method = "call", action = "<actionName>", params = {...}}'

-- One-line protocol summary stored as a "Usage" attribute on the gateway
-- instance, readable without invoking it (e.g. through a data-model inspector).
local USAGE = "This is an AgentGateway. Call gateway:Invoke(request), where request is "
	.. LIST_FORM
	.. " to list actions and their input schemas, or "
	.. CALL_FORM
	.. " to invoke one. Responses are {ok: boolean, result: any?, error: string?}."

-- Appended to every malformed-request error so a wrong first guess still
-- teaches the full request grammar.
local REQUEST_GRAMMAR = "Expected "
	.. LIST_FORM
	.. " to list available actions and their input schemas, or "
	.. CALL_FORM
	.. " to invoke one."

return {
	PROTOCOL_VERSION = PROTOCOL_VERSION,
	TAG = TAG,
	USAGE = USAGE,
	REQUEST_GRAMMAR = REQUEST_GRAMMAR,
}
