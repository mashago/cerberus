
local server_conf = require "global.server_conf"
local Log = require "log.logger"
local DBMgr = require "db.db_mgr"
local server_mgr = require "server.server_mgr"
local cerberus = require "cerberus"

require "db_svr.msg_handler"
require "db_svr.rpc_handler"

cerberus.start(function()
	Log.info("db_svr main_entry")
	server_mgr:create_mesh()

	for _, v in ipairs(server_conf._mysql_list) do
		assert(DBMgr.connect_to_mysql(v.ip, v.port, v.username, v.password, v.real_db_name), "connect_to_mysql fail " .. string.format("%s:%d %s:%s %s", v.ip, v.port, v.username, v.password, v.real_db_name))
	end

	server_conf._no_broadcast = true
end)

