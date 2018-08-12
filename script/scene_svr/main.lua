

local function main_entry(xml_doc)
	Log.info("scene_svr main_entry")

	g_funcs.load_scene(xml_doc)

	local RoleMgr = require "scene_svr.role_mgr"
	g_role_mgr = RoleMgr.new()

	require "scene_svr.net_event_handler"
	require "scene_svr.msg_handler"
	require "scene_svr.rpc_handler"
end

return main_entry
