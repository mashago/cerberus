

local function main_entry(xml_doc)
	Log.info("gate_svr main_entry")

	require "gate_svr.net_event_handler"
	require "gate_svr.msg_handler"
	require "gate_svr.rpc_handler"

	local UserMgr = require "gate_svr.user_mgr"
	g_user_mgr = UserMgr.new()

	local CommonHandler = require "gate_svr.common_handler"
	g_common_handler = CommonHandler.new()
end

return main_entry
