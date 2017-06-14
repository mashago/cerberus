
require "game_svr.init"

local function main_entry()
	Log.info("game_svr main_entry")

	register_msg_handler()

	-- connect to other server
	repeat
		local xml_doc = LuaTinyXMLDoc.create()
		if not xml_doc:load_file(g_conf_file) then
			Log.err("tinyxml load file fail %s", g_conf_file)
			break
		end

		local root_ele = xml_doc:first_child_element()
		if not root_ele then
			Log.err("tinyxml root_ele nil %s", g_conf_file)
			break
		end

		local connect_to_ele = root_ele:first_child_element("connect_to")
		if not connect_to_ele then
			Log.err("tinyxml connect_to_ele nil %s", g_conf_file)
			break
		end

		local address_ele = connect_to_ele:first_child_element("address")
		while address_ele do
			local ip = address_ele:string_attribute("ip")
			local port = address_ele:int_attribute("port")
			Services.add_connect_service(ip, port, "aaa")

			address_ele = address_ele:next_sibling_element()
		end
		Services.create_connect_timer()

		xml_doc = nil
	until true

	--[[
	local function timer_cb(arg)
		Log.info("timer_cb arg=%d", arg)
	end
	Timer.add_timer(1000, timer_cb, 10086, true)
	--]]
end

main_entry()
