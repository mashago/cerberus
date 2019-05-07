
local Log = require "log.logger"
local Env = require "env"
local server_mgr = require "server.server_mgr"
local cerberus = require "cerberus"
require "bridge_svr.net_event_handler"
require "bridge_svr.msg_handler"
require "bridge_svr.rpc_handler"

cerberus.start(function()
	Log.info("bridge_svr main_entry")
	server_mgr:create_mesh()

	local CommonMgr = require "bridge_svr.common_mgr"
	Env.common_mgr = CommonMgr.new()
end)
