
local Log = require "log.logger"
local Env = require "env"
require "scene_svr.net_event_handler"
require "scene_svr.msg_handler"
require "scene_svr.rpc_handler"

local function main_entry()
	Log.info("scene_svr main_entry")

	local RoleMgr = require "scene_svr.role_mgr"
	Env.role_mgr = RoleMgr.new()
end

return main_entry
