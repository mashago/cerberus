
package.path =  "script/core/?.lua;script/?.lua;" .. package.path

local conf_file = ... 

require "core.init"

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
		server_mgr:do_connect(v.ip, v.port)
	end

	local entry_path = Core.server_conf._path
	package.path = "script/" .. entry_path .. "/?.lua;" .. package.path
	local main_entry = require(entry_path .. ".main")
	main_entry()

	local hotfix = require("hotfix.main")
	hotfix.run()

	add_debug_timer()
end

local function main()
	Log.info("------------------------------")
	Log.info("conf_file=%s", conf_file)
	Log.info("------------------------------")
	math.randomseed(os.time())

	check_write_global()

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(conf_file) then
		Log.err("tinyxml load file fail %s", conf_file)
		return
	end
	local config = xml_doc:export()
	Log.debug("config=%s", Util.table_to_string(config))

	Core.server_conf = ServerConfig.new(config)
	Core.net_mgr = NetMgr.new()
	Core.timer_mgr = Timer.new()
	Core.server_mgr = ServerMgr.new()
	Core.rpc_mgr = RpcMgr.new()
	Core.http_mgr = HttpMgr.new()

	-- warp main logic in a rpc run
	Core.timer_mgr:fork(run)
end

local status, msg = xpcall(main, function(m) local msg = debug.traceback(m, 3) return msg end)

if not status then
	Log.err(msg)
end
