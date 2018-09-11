
local Log = require "core.log.logger"
local Env = require "env"
require "bridge_svr.net_event_handler"
require "bridge_svr.msg_handler"
require "bridge_svr.rpc_handler"

local function main_entry()
	Log.info("bridge_svr main_entry")

	local CommonMgr = require "bridge_svr.common_mgr"
	Env.common_mgr = CommonMgr.new()
end

return main_entry
