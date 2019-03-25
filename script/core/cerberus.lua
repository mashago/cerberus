
local rpc_mgr = require "rpc.rpc_mgr"

-- wrap most core api into cerberus
local cerberus = {}

function cerberus.start(...)
	return rpc_mgr:run(...)
end

return cerberus
