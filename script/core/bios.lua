
package.path =  "script/core/?.lua;script/?.lua;" .. package.path
package.cpath =  "luaclib/?.dll;luaclib/lib?.dll;luaclib/?.so;luaclib/lib?.so;luaclib/?.dylib;luaclib/lib?.dylib;" .. package.cpath

local Log = require "log.logger"
local server_conf = require "global.server_conf"
local cutil = require "cerberus.util"

local conf_file = ...

local status, msg = xpcall(
function()
	Log.info("------------------------------")
	Log.info("conf_file=%s", conf_file)
	Log.info("------------------------------")
	math.randomseed(os.time())

	local config = dofile(conf_file)
	server_conf:load(config)
	server_conf:print()

	-- local entry_path = server_conf._path
	-- package.path = "script/" .. entry_path .. "/?.lua;" .. package.path

	-- local main_entry = require(entry_path .. ".main")
	-- main_entry()
	require "main"
end,
function(m) 
	local msg = debug.traceback(m, 3)
	return msg 
end)
if not status then
	Log.err(msg)
	cutil.sleep(5)
end

