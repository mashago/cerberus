
local Log = require "log.logger"
local Env = require "env"
local server_mgr = require "server.server_mgr"
local cerberus = require "cerberus"

require "login_svr.net_event_handler"
require "login_svr.msg_handler"

cerberus.start(function()
	Log.info("login_svr main_entry")
	server_mgr:create_mesh()

	local AreaMgr = require "login_svr.area_mgr"
	Env.area_mgr = AreaMgr.new()

	local UserMgr = require "login_svr.user_mgr"
	Env.user_mgr = UserMgr.new()

end)
