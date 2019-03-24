
local Log = require "log.logger"
local Env = require "env"

require "client.msg_handler"
require "client.stdin_handler"

local function main_entry()
	Log.info("client main_entry")

	local Client = require "client.client"
	Env.client = Client.new()
	Env.client:load_server_list()
	-- Env.client:auto_run_cmd_once()

	local TimeCounter = require "client.time_counter"
	Env.time_counter = TimeCounter.new()

end

return main_entry
