
package.path =  "script/core/?.lua;script/?.lua;" .. package.path
package.cpath =  "luaclib/?.dll;luaclib/lib?.dll;luaclib/?.so;luaclib/lib?.so;luaclib/?.dylib;luaclib/lib?.dylib;" .. package.cpath

require "global.global_define"
require "global.data_struct_def"
require "ccall.ccall_funcs"
local Log = require "log.logger"
local server_conf = require "global.server_conf"
local cutil = require "cerberus.util"

local conf_file = ...

local status, msg = xpcall(
function()
	Log.info("------------------------------")
	Log.info("conf_file=%s", conf_file)
	Log.info("------------------------------")

	local Util = require "util.util"
	Util.check_write_global()

	local config = dofile(conf_file)
	server_conf:load(config)
	server_conf:print()

	local entry_path = server_conf._path
	package.path = "script/" .. entry_path .. "/?.lua;" .. package.path
	require("main")
end,
function(m) 
	local msg = debug.traceback(m, 3)
	return msg 
end)
if not status then
	Log.err(msg)
	cutil.sleep(5)
end

