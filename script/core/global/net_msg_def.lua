
_Null 			= 0
_Byte 			= 1
_Bool 			= 2
_Int 			= 3
_Float 			= 4
_Short 			= 5
_Int64 			= 6
_String			= 7
_Struct 		= 8
_StructString 	= 9 -- only for network transfer

_ByteArray 		= 11
_BoolArray		= 12
_IntArray		= 13
_FloatArray		= 14
_ShortArray 	= 15
_Int64Array 	= 16
_StringArray 	= 17
_StructArray 	= 18

MID = {}
MID._id_name_map = 
{
	-- msg for client
	[1] = "CLIENT_TEST",
	[2] = "CLIENT_TEST_RET",
	[3] = "RPC_TEST_REQ",
	[4] = "RPC_TEST_RET",

	-- login server handle
	[5] = "USER_LOGIN_REQ",
	[6] = "USER_LOGIN_RET",
	[7] = "AREA_LIST_REQ",
	[8] = "AREA_LIST_RET",
	[9] = "ROLE_LIST_REQ",
	[10] = "ROLE_LIST_RET",
	[11] = "CREATE_ROLE_REQ",
	[12] = "CREATE_ROLE_RET",
	[13] = "DELETE_ROLE_REQ",
	[14] = "DELETE_ROLE_RET",
	[15] = "SELECT_ROLE_REQ",
	[16] = "SELECT_ROLE_RET",

	-- router server handle
	[21] = "ROLE_ENTER_REQ",
	[22] = "ROLE_ENTER_RET",
	[23] = "ROLE_ATTR_RET",
	[24] = "ROLE_ATTR_CHANGE_REQ",
	[25] = "ROLE_ATTR_CHANGE_RET",

	-- msg for server
	[60001] = "REGISTER_SERVER_REQ",
	[60002] = "REGISTER_SERVER_RET",
	[60003] = "REGISTER_SERVER_BROADCAST",
	[60004] = "SERVER_DISCONNECT",
	[60005] = "REMOTE_CALL_REQ",
	[60006] = "REMOTE_CALL_RET",
	[60007] = "REGISTER_AREA_REQ",
	[60008] = "REGISTER_AREA_RET",
	[60009] = "INVITE_CONNECT_REQ",

	[60101] = "ROUTER_ROLE_ENTER_REQ",
	[60102] = "ROUTER_ROLE_ENTER_RET",
	[60103] = "ROUTER_ROLE_DISCONNECT",

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

RoleListStruct = 
{
	{ "role_id", _Int64 },
	{ "role_name", _String },
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
		{ "area_id", _Int },
	},
	[MID.ROLE_LIST_RET] =
	{
		{ "result", _Int },
		{ "area_id", _Int },
		{ "role_list", _StructArray, RoleListStruct },
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

	----------------------------------------

	[MID.REGISTER_SERVER_REQ] =
	{
		{ "server_id", _Int },
		{ "server_type", _Int },
		{ "single_scene_list", _IntArray },
		{ "from_to_scene_list", _IntArray },
	},

	[MID.REGISTER_SERVER_RET] =
	{
		{ "result", _Int },
		{ "server_id", _Int },
		{ "server_type", _Int },
	},

	[MID.REGISTER_SERVER_BROADCAST] =
	{
		{ "server_id", _Int },
		{ "server_type", _Int },
		{ "single_scene_list", _IntArray },
		{ "from_to_scene_list", _IntArray },
	},

	[MID.SERVER_DISCONNECT] =
	{
		{ "server_id", _Int },
	},


	[MID.REMOTE_CALL_REQ] =
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

	[MID.INVITE_CONNECT_REQ] =
	{
		{ "ip", _String },
		{ "port", _Int },
	},

	[MID.ROUTER_ROLE_ENTER_REQ] =
	{
		{ "role_id", _Int64 },
		{ "scene_id", _Int },
	},
	[MID.ROUTER_ROLE_ENTER_RET] =
	{
		{ "result", _Int },
		{ "role_id", _Int64 },
	},

	[MID.ROUTER_ROLE_DISCONNECT] =
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
	[MID.USER_LOGIN_REQ] = true,
	[MID.ROLE_ENTER_REQ] = true,

	[MID.REGISTER_SERVER_REQ] = true,
	[MID.REGISTER_SERVER_RET] = true,
	[MID.REGISTER_SERVER_BROADCAST] = true,
	[MID.SERVER_DISCONNECT] = true,
	[MID.REMOTE_CALL_REQ] = true,
	[MID.REMOTE_CALL_RET] = true,
	[MID.REGISTER_AREA_REQ] = true,
	[MID.REGISTER_AREA_RET] = true,
	[MID.INVITE_CONNECT_REQ] = true,

	[MID.ROUTER_ROLE_ENTER_REQ] = true,
	[MID.ROUTER_ROLE_ENTER_RET] = true,
}

--[[
-- handle these msg which only from trust mailbox
TRUST_MID =
{
	[MID.REGISTER_SERVER_REQ] = true,
	[MID.REGISTER_SERVER_RET] = true,
	[MID.REGISTER_SERVER_BROADCAST] = true,
	[MID.SERVER_DISCONNECT] = true,
	[MID.REMOTE_CALL_REQ] = true,
	[MID.REMOTE_CALL_RET] = true,
	[MID.REGISTER_AREA_REQ] = true,
	[MID.REGISTER_AREA_RET] = true,
}
--]]

