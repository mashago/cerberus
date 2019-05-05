
local Env = require "env"
local server_conf = require "global.server_conf"
local server_mgr = require "server.server_mgr"
local msg_def = require "global.net_msg_def"
local global_define = require "global.global_define"
local ServerType = global_define.ServerType
local MID = msg_def.MID

function g_net_event_server_connect(server_id)

	local server_info = server_mgr:get_server_by_id(server_id)
	if server_info._server_type == ServerType.LOGIN then
		-- register area
		local msg = 
		{
			area_list = server_conf._area_list,
		}

		server_info:send_msg(MID.s2s_register_area_req, msg)
	elseif server_info._server_type == ServerType.GATE then
		-- init gate connection num
		Env.common_mgr._gate_conn_map[server_info._server_id] = 0
	end
end

