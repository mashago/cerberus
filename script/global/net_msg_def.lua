
_Byte 			= 1
_Bool 			= 2
_Int 			= 3
_Float 			= 4
_Short 			= 5
_Int64 			= 6
_String			= 7
_Struct 		= 8

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

	[5] = "USER_LOGIN_REQ",
	[6] = "USER_LOGIN_RET",
	[7] = "AREA_LIST_REQ",
	[8] = "AREA_LIST_RET",
	[9] = "CREATE_ROLE_REQ",
	[10] = "CREATE_ROLE_RET",

	-- msg for server
	[60001] = "REGISTER_SERVER_REQ",
	[60002] = "REGISTER_SERVER_RET",
	[60003] = "REGISTER_SERVER_BROADCAST",
	[60004] = "SERVER_DISCONNECT",
	[60005] = "REMOTE_CALL_REQ",
	[60006] = "REMOTE_CALL_RET",
	[60007] = "REGISTER_AREA_REQ",
	[60008] = "REGISTER_AREA_RET",

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

}

-- do msg handler function directly
RAW_MID = 
{
	[MID.CLIENT_TEST] = true,
	[MID.RPC_TEST_REQ] = true,
	[MID.USER_LOGIN_REQ] = true,

	[MID.REGISTER_SERVER_REQ] = true,
	[MID.REGISTER_SERVER_RET] = true,
	[MID.REGISTER_SERVER_BROADCAST] = true,
	[MID.SERVER_DISCONNECT] = true,
	[MID.REMOTE_CALL_REQ] = true,
	[MID.REMOTE_CALL_RET] = true,
	[MID.REGISTER_AREA_REQ] = true,
	[MID.REGISTER_AREA_RET] = true,
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

