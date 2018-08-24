
local Core = require "core"
local Log = require "core.log.logger"
local g_funcs = require "core.global.global_funcs"

local function main_entry(xml_doc)
	Log.info("db_svr main_entry")

	require "db_svr.msg_handler"
	require "db_svr.rpc_handler"

	g_funcs.connect_to_mysql(xml_doc)

	Core.server_conf._no_broadcast = true

end

return main_entry
