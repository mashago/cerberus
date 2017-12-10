
package.path = package.path .. ";../script/?.lua"

require "core.init"

local function main()
	Log.info("------------------------------")
	Log.info("g_server_id=%d", g_server_id)
	Log.info("g_server_type=%d", g_server_type)
	Log.info("g_conf_file=%s", g_conf_file)
	Log.info("g_entry_file=%s", g_entry_file)
	Log.info("------------------------------")

	ServerConfig._server_id = g_server_id
	ServerConfig._server_type = g_server_type
	g_service_client = ServiceClient.new()

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end

	math.randomseed(os.time())

	require(g_entry_file)

	local hotfix = require("hotfix.main")
	hotfix.run()
end

local status, msg = xpcall(main, function(msg) local msg = debug.traceback(msg, 3) return msg end)

if not status then
	Log.err(msg)
end
