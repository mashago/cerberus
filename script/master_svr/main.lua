
local Log = require "log.logger"
local Env = require "env"

require "master_svr.net_event_handler"
require "master_svr.msg_handler"
require "master_svr.rpc_handler"

local function main_entry()
	Log.info("master_svr main_entry")
	
	local lfs = require("lfs")
	lfs.mkdir("dat")

	local PeerMgr = require "master_svr.peer_mgr"
	Env.peer_mgr = PeerMgr.new()
	Env.peer_mgr:load_peer_list()
end

return main_entry
