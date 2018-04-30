
package.path = package.path .. ";script/?.lua"

require "core.init"

local function add_debug_timer()
	local timer_cb = function()
		g_funcs.debug_timer_cb()
	end
	g_timer:add_timer(5000, timer_cb, 0, true)
end

local function main()
	Log.info("------------------------------")
	Log.info("g_server_id=%d", g_server_id)
	Log.info("g_server_type=%d", g_server_type)
	Log.info("g_conf_file=%s", g_conf_file)
	Log.info("g_entry_path=%s", g_entry_path)
	Log.info("------------------------------")


	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end
	g_server_conf = ServerConfig.new(g_server_id, g_server_type)
	g_funcs.load_address(xml_doc)

	g_timer = Timer.new()
	g_service_mgr = ServiceMgr.new()
	g_rpc_mgr = RpcMgr.new()
	g_http_mgr = HttpMgr.new()

	g_funcs.connect_to_servers(xml_doc)

	math.randomseed(os.time())

	local main_entry = require(g_entry_path .. ".main")
	main_entry(xml_doc)

	local hotfix = require("hotfix.main")
	hotfix.run()

	add_debug_timer()
end

local status, msg = xpcall(main, function(msg) local msg = debug.traceback(msg, 3) return msg end)

if not status then
	Log.err(msg)
end
