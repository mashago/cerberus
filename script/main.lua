
package.path = package.path .. ";../script/?.lua"

require "core.init"

local function add_debug_timer()
	local timer_cb = function()
		g_rpc_mgr:print()
	end
	g_timer:add_timer(5000, timer_cb, 0, true)
end

local function main()
	Log.info("------------------------------")
	Log.info("g_server_id=%d", g_server_id)
	Log.info("g_server_type=%d", g_server_type)
	Log.info("g_conf_file=%s", g_conf_file)
	Log.info("g_entry_file=%s", g_entry_file)
	Log.info("------------------------------")

	g_server_conf = ServerConfig.new(g_server_id, g_server_type)
	g_timer = Timer.new()
	g_service_server = ServiceServer.new()
	g_service_client = ServiceClient.new()
	g_service_mgr = ServiceMgr.new()
	g_rpc_mgr = RpcMgr.new()

	math.randomseed(os.time())

	require(g_entry_file)

	local hotfix = require("hotfix.main")
	hotfix.run()

	if g_server_type ~= 0 then
		-- add_debug_timer()
	end
end

local status, msg = xpcall(main, function(msg) local msg = debug.traceback(msg, 3) return msg end)

if not status then
	Log.err(msg)
end
