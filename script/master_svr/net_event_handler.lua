
local Env = require "env"
function g_net_event_server_disconnect(server_id)
	Env.peer_mgr:server_disconnect(server_id)	
end
