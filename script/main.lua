
package.path =  "script/core/?.lua;script/?.lua;" .. package.path
package.cpath =  "luaclib/?.dll;luaclib/lib?.dll;luaclib/?.so;luaclib/lib?.so;" .. package.cpath

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

local function add_debug_timer()
	local timer_cb = function()
		g_funcs.debug_timer_cb()
	end
	Core.timer_mgr:add_timer(5000, timer_cb, 0, true)
end

local function check_write_global()
	local mt = 
	{
		__newindex = function(t, k, v)
			local info = debug.getinfo(2)
			Log.warn("WRITE GLOBAL %s:%d %s %s [%s]"
			, info.short_src, info.currentline, info.namewhat, type(v), k)
			rawset(t, k, v)
		end
	}
	setmetatable(_G, mt)
end

local function run()

	local server_conf = Core.server_conf
	local ip = server_conf._ip
	local port = server_conf._port
	if ip ~= "" and port ~= 0 then
		Log.debug("main run listen ip=%s port=%d", ip, port)
		local listen_id = Core.net_mgr:listen(ip, port)
		Log.info("main run listen_id=%d", listen_id)
		if listen_id < 0 then
			Log.err("main run listen fail ip=%s port=%d", ip, port)
			return
		end
	end
	
	local server_mgr = Core.server_mgr
	for _, v in ipairs(Core.server_conf._connect_to) do
		Log.debug("connect ip=%s port=%d", v.ip, v.port)
		server_mgr:do_connect(v.ip, v.port)
	end

	local entry_path = Core.server_conf._path
	package.path = "script/" .. entry_path .. "/?.lua;" .. package.path
	local main_entry = require(entry_path .. ".main")
	main_entry()

	-- local lfs = require("lfs")
	-- local hotfix = require("hotfix.main")
	-- hotfix.run()

	add_debug_timer()
end

local function main()
	Log.info("------------------------------")
	Log.info("conf_file=%s", conf_file)
	Log.info("------------------------------")
	math.randomseed(os.time())

	check_write_global()

	local config = dofile(conf_file)
	Log.debug("config=%s", Util.table_to_string(config))

	Core.server_conf = ServerConfig.new(config)
	Core.net_mgr = NetMgr.new()
	Core.timer_mgr = Timer.new()
	Core.server_mgr = ServerMgr.new()
	Core.rpc_mgr = RpcMgr.new()
	Core.http_mgr = HttpMgr.new()

	-- warp main logic in a rpc run
	Core.rpc_mgr:run(run)
end

local status, msg = xpcall(main, function(m) local msg = debug.traceback(m, 3) return msg end)

if not status then
	Log.err(msg)
end
