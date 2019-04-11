
require "global.global_def"
require "global.data_struct_def"
require "ccall.ccall_funcs"

local server_mgr = require "server.server_mgr"
local server_conf = require "global.server_conf"
local cerberus = require "cerberus"

cerberus.start(function()
	server_mgr:create_mesh()

	local entry_path = server_conf._path
	package.path = "script/" .. entry_path .. "/?.lua;" .. package.path
	local main_entry = require(entry_path .. ".main")
	main_entry()

end)

