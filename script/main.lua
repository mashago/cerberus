
package.path = package.path .. ";../script/?.lua"

require "global.util.util"
require "global.sys.init"
require "global.global_def"
require "global.global_funcs"
require "global.server_conf"

local function main()
	Log.info("------------------------------")
	Log.info("g_server_id=%d", g_server_id)
	Log.info("g_server_type=%d", g_server_type)
	Log.info("g_conf_file=%s", g_conf_file)
	Log.info("g_entry_file=%s", g_entry_file)
	Log.info("------------------------------")

	ServerConfig._server_id = g_server_id
	ServerConfig._server_type = g_server_type

	math.randomseed(os.time())

	require(g_entry_file)
end

local status, msg = xpcall(main, function(msg) local msg = debug.traceback(msg, 3) return msg end)

if not status then
	Log.err(msg)
end
