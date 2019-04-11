
require "global.global_def"
require "global.data_struct_def"
require "global.net_msg_def"
require "global.msg_handler"
require "ccall.ccall_funcs"

local server_mgr = require "server.server_mgr"
local server_conf = require "global.server_conf"
local Util = require "util.util"
local cerberus = require "cerberus"

Util.check_write_global()

cerberus.start(function()
	server_mgr:create_mesh()

	local entry_path = server_conf._path
	package.path = "script/" .. entry_path .. "/?.lua;" .. package.path
	local main_entry = require(entry_path .. ".main")
	main_entry()

	-- Util.add_debug_timer()
end)

