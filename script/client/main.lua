
local Log = require "core.log.logger"
local Env = require "env"

require "client.msg_handler"
require "client.stdin_handler"

local function main_entry()
	Log.info("client main_entry")

	local Client = require "client.client"
	Env.g_client = Client.new()
	Env.g_client:load_server_list()
	-- Env.g_client:auto_run_cmd_once()

	local TimeCounter = require "client.time_counter"
	Env.g_time_counter = TimeCounter.new()

end

return main_entry
