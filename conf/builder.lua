
local server_pkg_id = 1
local login_server_port = 60001

local conf_list = 
{
{
"master",
[[
return {
	id = %d,
	type = %d,
	ip = "127.0.0.1",
	port = %d,
	path = "master_svr",
}
]],
}
,
{
"bridge",
[[
return {
	id = %d,
	type = %d,
	ip = "127.0.0.1",
	port = %d,
	path = "bridge_svr",

	area_list =
	{
		{
			id = 1,
		},
	},

	connect_to =
	{
		-- login_svr
		{
			ip = "127.0.0.1",
			port = %d,
		},
		-- master_svr
		{
			ip = "127.0.0.1",
			port = %d,
		}
	},
}
]],
}
,
{
"gate",
[[
return {
	id = %d,
	type = %d,
	ip = "127.0.0.1",
	port = %d,
	path = "gate_svr",

	connect_to =
	{
		-- master_svr
		{
			ip = "127.0.0.1",
			port = %d,
		}
	},
}
]],
2,
}
,
{
"scene",
[[
return {
	id = %d,
	type = %d,
	ip = "127.0.0.1",
	port = %d,
	path = "scene_svr",

	scene_list =
	{
		{
			single = 1,
		},
		{
			single = 2,
		},
		{
			from = 10,
			to = 11,
		},
	},

	connect_to =
	{
		-- master_svr
		{
			ip = "127.0.0.1",
			port = %d,
		}
	},
}
]],
}
,
{
"db_game",
[[
return {
	id = %d,
	type = %d,
	ip = "127.0.0.1",
	port = %d,
	path = "db_svr",

	connect_to =
	{
		-- master_svr
		{
			ip = "127.0.0.1",
			port = %d,
		}
	},

	mysql =
	{
		{
			ip = "127.0.0.1",
			port = 3306,
			username = "testmn",
			password = "123456",
			db_name = "mn_game_db",
			db_type = 2,
			db_suffix = "%d",
		},
	},
}
]],
2,
}
,
{
"sync_db",
[[
return {
	id = 0,
	type = 0,
	ip = "127.0.0.1",
	port = 0,
	path = "sync_db",

	mysql =
	{
		{
			ip = "127.0.0.1",
			port = 3306,
			username = "testmn",
			password = "123456",
			db_name = "mn_game_db",
			db_type = 2,
			db_suffix = "%d",
		},
	},
}
]],
}
}

function main()

	local server_type_map =
	{
		["db_game"] = 2,
		["master"] = 3,
		["bridge"] = 4,
		["gate"]   = 5,
		["scene"]  = 6,
		["public"] = 8,
		["sync_db"]  = 101,
	}

	local type_num_map = {}
	for type_name, v in pairs(server_type_map) do
		type_num_map[type_name] = 0
	end

	local function get_type_index(type_name)
		type_num_map[type_name] = type_num_map[type_name] + 1
		return type_num_map[type_name]
	end

	local total = 0
	local master_server_port = 0
	for k, v in ipairs(conf_list) do
		local type_name = v[1]
		local content = v[2]
		local server_num = v[3] or 1
		for i=1, server_num do
			local server_type = server_type_map[type_name]
			local type_index = get_type_index(type_name)
			local file_name = string.format("conf_%s%d_%d.lua", type_name, server_pkg_id, type_index)

			total = total + 1
			local server_id = server_pkg_id * 1000 + server_type * 100 + type_index
			local port = 6 * 10000 + server_pkg_id * 100 + total
			
			-- print("content=", content)
			print("server_id=", server_id, " server_type=", server_type, " port=", port)
			
			local output
			if type_name == "master" then
				master_server_port = port
				output = string.format(content, server_id, server_type, port)
			elseif type_name == "bridge" then
				output = string.format(content, server_id, server_type, port, login_server_port, master_server_port)
			elseif type_name == "gate" then
				output = string.format(content, server_id, server_type, port, master_server_port)
			elseif type_name == "public" then
			elseif type_name == "scene" then
				output = string.format(content, server_id, server_type, port, master_server_port)
			elseif type_name == "db_game" then
				output = string.format(content, server_id, server_type, port, master_server_port, server_pkg_id)
			elseif type_name == "sync_db" then
				output = string.format(content, server_pkg_id)
			else
				error("unknow server type ".. type_name)
			end

			local file = io.open(file_name, "w")
			file:write(output)
			file:close()
		end
	end
end

main()
