
local Log = require "log.logger"
local Env = require "env"
local server_mgr = require "server.server_mgr"
local cerberus = require "cerberus"

require "scene_svr.net_event_handler"
require "scene_svr.msg_handler"
require "scene_svr.rpc_handler"

cerberus.start(function()
	Log.info("scene_svr main_entry")
	server_mgr:create_mesh()

	local RoleMgr = require "scene_svr.role_mgr"
	Env.role_mgr = RoleMgr.new()
end)
