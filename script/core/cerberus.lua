
local rpc_mgr = require "rpc.rpc_mgr"
local cnetwork = require "cerberus.network"

-- wrap most core api into cerberus
local cerberus = {}

function cerberus.start(...)
	return rpc_mgr:run(...)
end

function cerberus:connect(ip, port)
	return rpc_mgr:sync(cnetwork.connect, ip, port)
end

function cerberus:listen(ip, port)
	return rpc_mgr:sync(cnetwork.listen, ip, port)
end

return cerberus
