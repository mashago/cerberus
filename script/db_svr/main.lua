
local Core = require "core"
local Log = require "log.logger"
local DBMgr = require "db.db_mgr"

require "db_svr.msg_handler"
require "db_svr.rpc_handler"

local function main_entry()
	Log.info("db_svr main_entry")

	for _, v in ipairs(Core.server_conf._mysql_list) do
		assert(DBMgr.connect_to_mysql(v.ip, v.port, v.username, v.password, v.real_db_name), "connect_to_mysql fail " .. string.format("%s:%d %s:%s %s", v.ip, v.port, v.username, v.password, v.real_db_name))
	end

	Core.server_conf._no_broadcast = true

end

return main_entry
