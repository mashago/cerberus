
require "global.global_def"
require "global.data_struct_def"
require "global.net_msg_def"
require "global.msg_handler"
require "ccall.ccall_funcs"

local Core = require "core"
local server_conf = require "global.server_conf"
local net_mgr = require "net.net_mgr"
local timer = require "timer.timer"
local server_mgr = require "server.server_mgr"
local rpc_mgr = require "rpc.rpc_mgr"
local http_mgr = require "http.http_mgr"
local Util = require "util.util"
local cerberus = require "cerberus"

Util.check_write_global()

Core.server_conf = server_conf
Core.net_mgr = net_mgr
Core.timer_mgr = timer
Core.server_mgr = server_mgr
Core.rpc_mgr = rpc_mgr
Core.http_mgr = http_mgr

cerberus.start(function()
	server_mgr:create_mesh()

	local entry_path = server_conf._path
	package.path = "script/" .. entry_path .. "/?.lua;" .. package.path
	local main_entry = require(entry_path .. ".main")
	main_entry()

	Util.add_debug_timer()
end)

