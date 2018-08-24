
package.path =  "script/core/?.lua;script/?.lua;" .. package.path

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

local function main()
	Log.info("------------------------------")
	Log.info("g_server_id=%d", g_server_id)
	Log.info("g_server_type=%d", g_server_type)
	Log.info("g_conf_file=%s", g_conf_file)
	Log.info("g_entry_path=%s", g_entry_path)
	Log.info("------------------------------")

	check_write_global()

	local xml_doc = LuaTinyXMLDoc.create()
	if not xml_doc:load_file(g_conf_file) then
		Log.err("tinyxml load file fail %s", g_conf_file)
		return
	end


	Core.server_conf = ServerConfig.new(g_server_id, g_server_type)
	g_funcs.load_address(xml_doc)

	Core.net_mgr = NetMgr.new()
	Core.timer_mgr = Timer.new()
	Core.server_mgr = ServerMgr.new()
	Core.rpc_mgr = RpcMgr.new()
	Core.http_mgr = HttpMgr.new()

	g_funcs.connect_to_servers(xml_doc)

	math.randomseed(os.time())

	package.path = "script/" .. g_entry_path .. "/?.lua;" .. package.path
	local main_entry = require(g_entry_path .. ".main")
	main_entry(xml_doc)

	local hotfix = require("hotfix.main")
	hotfix.run()

	add_debug_timer()
end

local status, msg = xpcall(main, function(msg) local msg = debug.traceback(msg, 3) return msg end)

if not status then
	Log.err(msg)
end
