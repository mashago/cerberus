
local Log = require "core.log.logger"
local g_funcs = require "core.global.global_funcs"
local Env = require "env"
require "bridge_svr.net_event_handler"
require "bridge_svr.msg_handler"
require "bridge_svr.rpc_handler"

local function main_entry(xml_doc)
	Log.info("bridge_svr main_entry")


	g_funcs.load_scene(xml_doc)
	g_funcs.load_area(xml_doc)

	local CommonMgr = require "bridge_svr.common_mgr"
	Env.g_common_mgr = CommonMgr.new()
	
end

return main_entry
