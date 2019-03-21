
require "global.global_def"
require "global.data_struct_def"
require "global.net_msg_def"
require "global.msg_handler"
require "ccall.ccall_funcs"

local Core = require "core"
local Log = require "log.logger"
local server_conf = require "global.server_conf"
local NetMgr = require "net.net_mgr"
local Timer = require "timer.timer"
local ServerMgr = require "server.server_mgr"
local RpcMgr = require "rpc.rpc_mgr"
local HttpMgr = require "http.http_mgr"
local g_funcs = require "global.global_funcs"
local Util = require "util.util"
local cutil = require "cerberus.util"

Util.check_write_global()

Core.server_conf = server_conf
Core.net_mgr = NetMgr.new()
Core.timer_mgr = Timer.new()
Core.server_mgr = ServerMgr.new()
Core.rpc_mgr = RpcMgr.new()
Core.http_mgr = HttpMgr.new()

-- warp main logic in a rpc run
Core.rpc_mgr:run(function()
	Core.server_mgr:create_mesh()

	local entry_path = Core.server_conf._path
	package.path = "script/" .. entry_path .. "/?.lua;" .. package.path
	local main_entry = require(entry_path .. ".main")
	main_entry()

	Util.add_debug_timer()
end)

