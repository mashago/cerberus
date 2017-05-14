
package.path = package.path .. ";../script/?.lua"

require "sys.init"

local function main()
	print("g_server_id=", g_server_id)
	print("g_server_type=", g_server_type)
	print("g_entry_file=", g_entry_file)

	require(g_entry_file)
end

local status, msg = xpcall(main, function(msg) local msg = debug.traceback(msg, 3) return msg end)

if not status then
	print(msg)
end
