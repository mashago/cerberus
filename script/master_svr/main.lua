
local Log = require "log.logger"
local Env = require "env"
local server_mgr = require "server.server_mgr"
local cerberus = require "cerberus"

require "master_svr.net_event_handler"
require "master_svr.msg_handler"
require "master_svr.rpc_handler"

cerberus.start(function()
	Log.info("master_svr main_entry")
	server_mgr:create_mesh()
	
	local lfs = require("lfs")
	lfs.mkdir("dat")

	local PeerMgr = require "master_svr.peer_mgr"
	Env.peer_mgr = PeerMgr.new()
	Env.peer_mgr:load_peer_list()
end)
