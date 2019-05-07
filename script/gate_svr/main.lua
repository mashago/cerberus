
local Log = require "log.logger"
local Env = require "env"
local server_mgr = require "server.server_mgr"
local cerberus = require "cerberus"

require "gate_svr.net_event_handler"
require "gate_svr.msg_handler"
require "gate_svr.rpc_handler"

cerberus.start(function()
	Log.info("gate_svr main_entry")
	server_mgr:create_mesh()

	local UserMgr = require "gate_svr.user_mgr"
	Env.user_mgr = UserMgr.new()

	local CommonHandler = require "gate_svr.common_handler"
	Env.common_handler = CommonHandler.new()
end)
