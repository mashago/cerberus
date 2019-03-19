
package.path =  "script/core/?.lua;script/?.lua;" .. package.path
package.cpath =  "luaclib/?.dll;luaclib/lib?.dll;luaclib/?.so;luaclib/lib?.so;luaclib/?.dylib;luaclib/lib?.dylib;" .. package.cpath

require "core.global.global_def"
require "core.global.data_struct_def"
require "core.global.net_msg_def"
require "core.global.msg_handler"
require "core.ccall.ccall_funcs"

local Core = require "core"
local Log = require "log.logger"
local ServerConfig = require "global.server_conf"
local NetMgr = require "net.net_mgr"
local Timer = require "timer.timer"
local ServerMgr = require "server.server_mgr"
local RpcMgr = require "rpc.rpc_mgr"
local HttpMgr = require "http.http_mgr"
local g_funcs = require "global.global_funcs"
local Util = require "util.util"
local cutil = require "cerberus.util"

local conf_file = ...

local function main()
	Log.info("------------------------------")
	Log.info("conf_file=%s", conf_file)
	Log.info("------------------------------")
	math.randomseed(os.time())

	Util.check_write_global()

	local config = dofile(conf_file)
	Log.debug("config=%s", Util.table_to_string(config))

	Core.server_conf = ServerConfig.new(config)
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
end

local status, msg = xpcall(main, function(m) local msg = debug.traceback(m, 3) return msg end)

if not status then
	Log.err(msg)
end
