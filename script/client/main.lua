
local Log = require "core.log.logger"

local function main_entry(xml_doc)
	Log.info("client main_entry")

	require "client.msg_handler"
	require "client.stdin_handler"

	local Client = require "client.client"
	g_client = Client.new()
	g_client:load_server_list(xml_doc)
	-- g_client:auto_run_cmd_once()

	local TimeCounter = require "client.time_counter"
	g_time_counter = TimeCounter.new()

end

return main_entry
