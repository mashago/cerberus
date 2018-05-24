
local server_pkg_id = 1
local login_server_port = 60001

local conf_list = 
{
{
"master",
[[
<?xml version="1.0" encoding="UTF-8"?>
<server id = "%d" type = "%d" ip = "127.0.0.1" port = "%d" path = "master_svr"> 
</server>
]]
}
,
{
"bridge",
[[
<?xml version="1.0" encoding="UTF-8"?>
<server id = "%d" type = "%d" ip = "127.0.0.1" port = "%d" path = "bridge_svr"> 

	<area_list>
		<area id = "1"/>
	</area_list>

	<connect_to>
		<!-- login_svr -->
		<address ip = "127.0.0.1" port = "%d"/>
		<!-- master_svr -->
		<address ip = "127.0.0.1" port = "%d"/>
	</connect_to>
</server>
]]
}
,
{
"gate",
[[
<?xml version="1.0" encoding="UTF-8"?>
<server id = "%d" type = "%d" ip = "127.0.0.1" port = "%d" path = "gate_svr"> 
	<connect_to>
		<!-- master_svr -->
		<address ip = "127.0.0.1" port = "%d"/>
	</connect_to>
</server>
]]
}
,
{
"gate",
[[
<?xml version="1.0" encoding="UTF-8"?>
<server id = "%d" type = "%d" ip = "127.0.0.1" port = "%d" path = "gate_svr"> 
	<connect_to>
		<!-- master_svr -->
		<address ip = "127.0.0.1" port = "%d"/>
	</connect_to>
</server>
]]
}
,
{
"scene",
[[
<?xml version="1.0" encoding="UTF-8"?>
<server id = "%d" type = "%d" ip = "127.0.0.1" port = "%d" path = "scene_svr"> 
	<scene_list>
		<scene single = "1"/>
		<scene single = "2"/>
		<scene from = "10" to = "11"/>
		<!-- <scene from = "20" to = "21"/> -->
	</scene_list>

	<connect_to>
		<!-- master_svr -->
		<address ip = "127.0.0.1" port = "%d"/>
	</connect_to>
</server>
]]
}
,
{
"db_game",
[[
<?xml version="1.0" encoding="UTF-8"?>
<server id = "%d" type = "%d" ip = "127.0.0.1" port = "%d" path = "db_svr"> 

	<connect_to>
		<!-- master_svr -->
		<address ip = "127.0.0.1" port = "%d"/>
	</connect_to>

	<mysql>
		<info ip = "127.0.0.1" port = "3306" username = "testmn" password = "123456" db_name = "mn_game_db" db_type = "2" db_suffix = "%d"/>
	</mysql>

</server>
]]
}
,
{
"db_game",
[[
<?xml version="1.0" encoding="UTF-8"?>
<server id = "%d" type = "%d" ip = "127.0.0.1" port = "%d" path = "db_svr"> 

	<connect_to>
		<!-- master_svr -->
		<address ip = "127.0.0.1" port = "%d"/>
	</connect_to>

	<mysql>
		<info ip = "127.0.0.1" port = "3306" username = "testmn" password = "123456" db_name = "mn_game_db" db_type = "2" db_suffix = "%d"/>
	</mysql>

</server>
]]
}
,
{
"sync_db",
[[
<?xml version="1.0" encoding="UTF-8"?>
<server id = "0" type = "0" ip = "127.0.0.1" port = "0" path = "sync_db" auto_shutdown = "1"> 

	<mysql>
		<info ip = "127.0.0.1" port = "3306" username = "testmn" password = "123456" db_name = "mn_game_db" db_type = "2" db_suffix = "%d"/>
	</mysql>

</server>
]]
}
}

function main()

	local server_type_map =
	{
		["db_game"] = 2,
		["master"] = 3,
		["bridge"] = 4,
		["gate"] 	= 5,
		["public"] = 6,
		["scene"]  = 7,
		["sync_db"]  = 101,
	}

	local type_num_map = {}
	for type_name, v in pairs(server_type_map) do
		type_num_map[type_name] = 0
	end

	local function get_type_num(type_name)
		type_num_map[type_name] = type_num_map[type_name] + 1
		return type_num_map[type_name]
	end

	local master_server_port = 0
	for k, v in ipairs(conf_list) do
		local type_name = v[1]
		local server_type = server_type_map[type_name]
		local content = v[2]
		local type_num = get_type_num(type_name)
		local file_name = string.format("conf_%s%d_%d.xml", type_name, server_pkg_id, type_num)

		local server_id = server_pkg_id * 1000 + server_type * 100 + type_num
		local port = 6 * 10000 + server_pkg_id * 100 + k
		
		-- print("content=", content)
		-- print("server_id=", server_id, " server_type=", server_type, " port=", port)
		
		if type_name == "master" then
			master_server_port = port
			content = string.format(content, server_id, server_type, port)
		elseif type_name == "bridge" then
			content = string.format(content, server_id, server_type, port, login_server_port, master_server_port)
		elseif type_name == "gate" then
			content = string.format(content, server_id, server_type, port, master_server_port)
		elseif type_name == "public" then
		elseif type_name == "scene" then
			content = string.format(content, server_id, server_type, port, master_server_port)
		elseif type_name == "db_game" then
			content = string.format(content, server_id, server_type, port, master_server_port, server_pkg_id)
		elseif type_name == "sync_db" then
			content = string.format(content, server_pkg_id)
		else
			error("unknow server type ".. type_name)
		end

		local file = io.open(file_name, "w")
		file:write(content)
		file:close()
	end
end

main()
