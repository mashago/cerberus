
local Util = {}

function Util.table_to_string(tb)
	if type(tb) ~= "table" then
		error("Sorry, it's not table, it is " .. type(tb) .. ".")
	end

	local function _list_table(t, table_list, level)
		local ret = ""
		local indent = string.rep(" ", level*4)

		for k, v in pairs(t) do
			local quo = type(k) == "string" and "\"" or ""
			ret = ret .. indent .. "[" .. quo .. tostring(k) .. quo .. "] = "

			if type(v) == "table" then
				local t_name = table_list[v]
				if t_name then
					ret = ret .. tostring(v) .. " -- > [\"" .. t_name .. "\"]\n"
				else
					table_list[v] = tostring(k)
					ret = ret .. "{\n"
					ret = ret .. _list_table(v, table_list, level+1)
					ret = ret .. indent .. "}\n"
				end
			elseif type(v) == "string" then
				ret = ret .. "\"" .. tostring(v) .. "\"\n"
			else
				ret = ret .. tostring(v) .. "\n"
			end
		end

		local mt = getmetatable(t)
		if mt then
			ret = ret .. "\n"
			local t_name = table_list[mt]
			ret = ret .. indent .. "<metatable> = "

			if t_name then
				ret = ret .. tostring(mt) .. " -- > [\"" .. t_name .. "\"]\n"
			else
				ret = ret .. "{\n"
				ret = ret .. _list_table(mt, table_list, level+1)
				ret = ret .. indent .. "}\n"
			end

		end

		return ret
	end

	local ret = " {\n"
	local table_list = {}
	table_list[tb] = "root table"
	ret = ret .. _list_table(tb, table_list, 1)
	ret = ret .. "}"
	return ret
end

function Util.split_string(str, sep)
	local head = 1
	local ret = {}
	while true do
		local tail = string.find(str, sep, head)
		if not tail then
			local s = string.sub(str, head, string.len(str))
			if #s > 0 then
				table.insert(ret, s)
			end
			break
		end
		local s = string.sub(str, head, tail - 1)
		if #s > 0 then
			table.insert(ret, s)
		end
		head = tail + string.len(sep)
	end
	return ret 
end

function Util.serialize(obj)  
	local lua = ""  
	local t = type(obj)  
	if t == "number" then  
		lua = lua .. obj  
	elseif t == "boolean" then  
		lua = lua .. tostring(obj)  
	elseif t == "string" then  
		lua = lua .. string.format("%q", obj)  
	elseif t == "table" then  
		--lua = lua .. "{\n"  
		lua = lua .. "{"  
	for k, v in pairs(obj) do  
		--lua = lua .. "[" .. Util.serialize(k) .. "]=" .. Util.serialize(v) .. ",\n"  
		lua = lua .. "[" .. Util.serialize(k) .. "]=" .. Util.serialize(v) .. ","  
	end  
	local metatable = getmetatable(obj)  
		if metatable ~= nil and type(metatable.__index) == "table" then  
		for k, v in pairs(metatable.__index) do  
			-- lua = lua .. "[" .. Util.serialize(k) .. "]=" .. Util.serialize(v) .. ",\n"  
			lua = lua .. "[" .. Util.serialize(k) .. "]=" .. Util.serialize(v) .. ","  
		end  
	end  
		lua = lua .. "}"  
	elseif t == "nil" then  
		return nil  
	else  
		error("can not serialize a " .. t .. " type.")  
	end  
	return lua  
end  
  
function Util.unserialize(lua)  
	local t = type(lua)  
	if t == "nil" or lua == "" then  
		return nil  
	elseif t == "number" or t == "string" or t == "boolean" then  
		lua = tostring(lua)  
	else  
		error("can not unserialize a " .. t .. " type.")  
	end  
	lua = "return " .. lua  
	local func = load(lua)  
	if func == nil then  
		return nil  
	end  
	return func()  
end

--[[
local t = 
{
	[1] = {
		[11] =
		{
			[111] = true,
			[112] = true,
		},
		[12] =
		{
			[121] = true,
		},
	},
	[2] = {
		[21] =
		{
		},
		[22] =
		{
			[221] = true,
		},
	},
}
==>
{
	{1, 11, 111},
	{1, 11, 112},
	{1, 12, 121},
	{2, 22, 221},
}
--]]
function Util.map2path(input, output, tmp)
	for k, v in pairs(input) do
		local mid = {}
		if tmp then
			for _, key in ipairs(tmp) do
				table.insert(mid, key)
			end
		end

		if type(v) == 'table' then
			table.insert(mid, k)
			Util.map2path(v, output, mid)
		elseif type(v) == 'boolean' and v == true then
			table.insert(mid, k)
			table.insert(output, mid)
		end
	end
end

function Util.map2mergepath(input, output, tmp)
	local terminal = {}
	for k, v in pairs(input) do
		if type(v) == 'table' then
			local mid = {}
			if tmp then
				for _, key in ipairs(tmp) do
					table.insert(mid, key)
				end
			end
			table.insert(mid, k)
			local terminal2 = Util.map2mergepath(v, output, mid)
			if next(terminal2) then
				table.insert(mid, terminal2)
				table.insert(output, mid)
			end
		elseif type(v) == 'boolean' and v == true then
			table.insert(terminal, k)
		end
	end
	if next(terminal) and not tmp then
		table.insert(output, {terminal})
	end
	return terminal
end

return Util
