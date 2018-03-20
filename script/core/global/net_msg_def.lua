
MID = {}
MID._id_name_map = 
{
	-- msg for test
	[1] = "CLIENT_TEST",
	[2] = "CLIENT_TEST_RET",
	[3] = "RPC_TEST_REQ",
	[4] = "RPC_TEST_RET",
	[5] = "RPC_NOCB_TEST_REQ",
	[6] = "RPC_MIX_TEST_REQ",

	-- login server handle
	[10005] = "USER_LOGIN_REQ",
	[10006] = "USER_LOGIN_RET",
	[10007] = "AREA_LIST_REQ",
	[10008] = "AREA_LIST_RET",
	[10009] = "ROLE_LIST_REQ",
	[10010] = "ROLE_LIST_RET",
	[10011] = "CREATE_ROLE_REQ",
	[10012] = "CREATE_ROLE_RET",
	[10013] = "DELETE_ROLE_REQ",
	[10014] = "DELETE_ROLE_RET",
	[10015] = "SELECT_ROLE_REQ",
	[10016] = "SELECT_ROLE_RET",

	-- gate server handle
	[20021] = "ROLE_ENTER_REQ",
	[20022] = "ROLE_ENTER_RET",
	[20023] = "ROLE_ATTR_RET",
	[20024] = "ROLE_ATTR_CHANGE_REQ",
	[20025] = "ROLE_ATTR_CHANGE_RET",
	[20026] = "ATTR_INSERT_RET",
	[20027] = "ATTR_DELETE_RET",
	[20028] = "ATTR_MODIFY_RET",

	-- msg for server
	-- about master_svr
	
	[60004] = "SHAKE_HAND_REQ", -- after connect to success, send this
	[60005] = "SHAKE_HAND_RET",
	[60006] = "SHAKE_HAND_INVITE",

	[60007] = "REMOTE_CALL_REQ",
	[60008] = "REMOTE_CALL_NOCB_REQ",
	[60009] = "REMOTE_CALL_RET",

	[60010] = "REGISTER_AREA_REQ",
	[60011] = "REGISTER_AREA_RET",

	[60101] = "GATE_ROLE_ENTER_REQ",
	[60102] = "GATE_ROLE_ENTER_RET",
	[60103] = "GATE_ROLE_DISCONNECT",

	-- msg for db
	[70001] = "DB_INSERT",
	[70002] = "DB_DELETE",
	[70003] = "DB_UPDATE",
}

local function create_msg_id_array()
	for k, v in pairs(MID._id_name_map) do
		MID[v] = k
	end
end
create_msg_id_array()

TestStruct = 
{
	{ "byte", _Byte },
	{ "bool", _Bool },
	{ "int", _Int },
	{ "float", _Float },
	{ "short", _Short },
	{ "int64", _Int64 },
	{ "string", _String },
}

AreaListStruct = 
{
	{ "area_id", _Int },
	{ "area_name", _String },
}


AreaRoleStruct = 
{
	{ "role_id", _Int64 },
	{ "role_name", _String },
}

AreaRoleListStruct = 
{
	{ "area_id", _Int },
	{ "role_list", _StructArray, AreaRoleStruct },
}

ServerAddrStruct =
{
	{ "ip", _String },
	{ "port", _Int },
}

-----------------------------------

ByteAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Byte },
}

BoolAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Bool },
}

IntAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Int },
}

FloatAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Float },
}

ShortAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Short },
}

Int64AttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _Int64 },
}

StringAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _String },
}

StructAttrStruct = 
{
	{ "attr_id", _Int },
	{ "value", _StructString },
}

AttrTableStruct =
{
	{ "byte_attr_list", _StructArray, ByteAttrStruct },
	{ "bool_attr_list", _StructArray, BoolAttrStruct },
	{ "int_attr_list", _StructArray, IntAttrStruct },
	{ "float_attr_list", _StructArray, FloatAttrStruct },
	{ "short_attr_list", _StructArray, ShortAttrStruct },
	{ "int64_attr_list", _StructArray, Int64AttrStruct },
	{ "string_attr_list", _StructArray, StringAttrStruct },
	{ "struct_attr_list", _StructArray, StructAttrStruct },
}

ModifyAttrTableStruct =
{
	{ "key", _Struct, AttrTableStruct },
	{ "attr_table", _Struct, AttrTableStruct },
}

-----------------------------------


MSG_DEF_MAP = {}
MSG_DEF_MAP =
{
	[MID.CLIENT_TEST] =
	{
		{ "byte", _Byte },
		{ "bool", _Bool },
		{ "int", _Int },
		{ "float", _Float },
		{ "short", _Short },
		{ "int64", _Int64 },
		{ "string", _String },
		{ "struct", _Struct, TestStruct },

		{ "bytearray", _ByteArray },
		{ "boolarray", _BoolArray },
		{ "intarray", _IntArray },
		{ "floatarray", _FloatArray },
		{ "shortarray", _ShortArray },
		{ "int64array", _Int64Array },
		{ "stringarray", _StringArray },
		{ "structarray", _StructArray, TestStruct },
	},

	[MID.CLIENT_TEST_RET] =
	{
		{ "byte", _Byte },
		{ "bool", _Bool },
		{ "int", _Int },
		{ "float", _Float },
		{ "short", _Short },
		{ "int64", _Int64 },
		{ "string", _String },
		{ "struct", _Struct, TestStruct },

		{ "bytearray", _ByteArray },
		{ "boolarray", _BoolArray },
		{ "intarray", _IntArray },
		{ "floatarray", _FloatArray },
		{ "shortarray", _ShortArray },
		{ "int64array", _Int64Array },
		{ "stringarray", _StringArray },
		{ "structarray", _StructArray, TestStruct },
	},

	[MID.RPC_TEST_REQ] =
	{
		{ "buff", _String },
	},
	[MID.RPC_TEST_RET] =
	{
		{ "result", _Int },
		{ "buff", _String },
		{ "sum", _Int },
	},
	[MID.RPC_NOCB_TEST_REQ] =
	{
		{ "buff", _String },
	},
	[MID.RPC_MIX_TEST_REQ] =
	{
		{ "buff", _String },
	},

	-----------------------------------------------------------

	[MID.USER_LOGIN_REQ] =
	{
		{ "username", _String },
		{ "password", _String },
		{ "channel_id", _Int },
	},
	[MID.USER_LOGIN_RET] =
	{
		{ "result", _Int },
	},

	[MID.AREA_LIST_REQ] =
	{
	},
	[MID.AREA_LIST_RET] =
	{
		{ "area_list", _StructArray, AreaListStruct },
	},

	[MID.ROLE_LIST_REQ] =
	{
	},
	[MID.ROLE_LIST_RET] =
	{
		{ "result", _Int },
		{ "area_role_list", _StructArray, AreaRoleListStruct },
	},

	[MID.CREATE_ROLE_REQ] =
	{
		{ "area_id", _Int },
		{ "role_name", _String },
	},
	[MID.CREATE_ROLE_RET] =
	{
		{ "result", _Int },
		{ "role_id", _Int64 },
	},

	[MID.DELETE_ROLE_REQ] =
	{
		{ "area_id", _Int },
		{ "role_id", _Int64 },
	},
	[MID.DELETE_ROLE_RET] =
	{
		{ "result", _Int },
	},

	[MID.SELECT_ROLE_REQ] =
	{
		{ "area_id", _Int },
		{ "role_id", _Int64 },
	},
	[MID.SELECT_ROLE_RET] =
	{
		{ "result", _Int },
		{ "ip", _String },
		{ "port", _Int },
		{ "user_id", _Int64 },
		{ "token", _String },
	},

	----------------------------------------

	[MID.ROLE_ENTER_REQ] =
	{
		{ "user_id", _Int64 },
		{ "token", _String },
	},
	[MID.ROLE_ENTER_RET] =
	{
		{ "result", _Int },
	},

	[MID.ROLE_ATTR_RET] =
	{
		{ "role_id", _Int64 },
		{ "attr_table", _Struct, AttrTableStruct },
	},

	[MID.ROLE_ATTR_CHANGE_REQ] =
	{
		{ "attr_table", _Struct, AttrTableStruct },
	},

	[MID.ROLE_ATTR_CHANGE_RET] =
	{
		{ "role_id", _Int64 },
		{ "attr_table", _Struct, AttrTableStruct },
	},

	[MID.ATTR_INSERT_RET] =
	{
		{ "sheet_name", _String },
		{ "attr_list", _StructArray, AttrTableStruct },
	},

	[MID.ATTR_DELETE_RET] =
	{
		{ "sheet_name", _String },
		{ "attr_list", _StructArray, AttrTableStruct },
	},

	[MID.ATTR_MODIFY_RET] =
	{
		{ "sheet_name", _String },
		{ "attr_list", _StructArray, ModifyAttrTableStruct },
	},

	----------------------------------------

	[MID.SHAKE_HAND_REQ] =
	{
		{ "server_id", _Int },
		{ "server_type", _Int },
		{ "single_scene_list", _IntArray },
		{ "from_to_scene_list", _IntArray },
		{ "ip", _String },
		{ "port", _Int },
	},

	[MID.SHAKE_HAND_RET] =
	{
		{ "result", _Int },
		{ "server_id", _Int },
		{ "server_type", _Int },
		{ "single_scene_list", _IntArray },
		{ "from_to_scene_list", _IntArray },
	},

	[MID.SHAKE_HAND_INVITE] =
	{
		{ "server_list", _StructArray, ServerAddrStruct },
	},


	[MID.REMOTE_CALL_REQ] =
	{
		{ "from_server_id", _Int },
		{ "to_server_id", _Int },
		{ "session_id", _Int64 },
		{ "func_name", _String },
		{ "param", _String },
	},

	[MID.REMOTE_CALL_NOCB_REQ] =
	{
		{ "from_server_id", _Int },
		{ "to_server_id", _Int },
		{ "session_id", _Int64 },
		{ "func_name", _String },
		{ "param", _String },
	},

	[MID.REMOTE_CALL_RET] =
	{
		{ "result", _Bool },
		{ "from_server_id", _Int },
		{ "to_server_id", _Int },
		{ "session_id", _Int64 },
		{ "param", _String },
	},

	[MID.REGISTER_AREA_REQ] =
	{
		{ "area_list", _IntArray },
	},

	[MID.REGISTER_AREA_RET] =
	{
		{ "result", _Int },
	},

	[MID.GATE_ROLE_ENTER_REQ] =
	{
		{ "role_id", _Int64 },
		{ "scene_id", _Int },
	},
	[MID.GATE_ROLE_ENTER_RET] =
	{
		{ "result", _Int },
		{ "role_id", _Int64 },
	},

	[MID.GATE_ROLE_DISCONNECT] =
	{
	},

	-----------------------------------------------------------

	[MID.DB_INSERT] =
	{
		{ "db_name", _String },
		{ "table_name", _String },
		{ "fields", _StringArray },
		{ "values", _StringArray },
	},

	[MID.DB_DELETE] =
	{
		{ "db_name", _String },
		{ "table_name", _String },
		{ "conditions", _String }, -- a table string
	},

}

-- do msg handler function directly
RAW_MID = 
{
	[MID.CLIENT_TEST] = true,
	[MID.RPC_TEST_REQ] = true,
	[MID.RPC_NOCB_TEST_REQ] = true,
	[MID.RPC_MIX_TEST_REQ] = true,

	[MID.SHAKE_HAND_REQ] = true,
	[MID.SHAKE_HAND_RET] = true,
	[MID.SHAKE_HAND_INVITE] = true,

	[MID.USER_LOGIN_REQ] = true,
	[MID.ROLE_ENTER_REQ] = true,

	[MID.REMOTE_CALL_REQ] = true,
	[MID.REMOTE_CALL_NOCB_REQ] = true,
	[MID.REMOTE_CALL_RET] = true,
	[MID.REGISTER_AREA_REQ] = true,
	[MID.REGISTER_AREA_RET] = true,

	[MID.GATE_ROLE_ENTER_REQ] = true,
	[MID.GATE_ROLE_ENTER_RET] = true,
}

--[[
-- handle these msg which only from trust mailbox
TRUST_MID =
{
	[MID.REMOTE_CALL_REQ] = true,
	[MID.REMOTE_CALL_RET] = true,
	[MID.REGISTER_AREA_REQ] = true,
	[MID.REGISTER_AREA_RET] = true,
}
--]]

