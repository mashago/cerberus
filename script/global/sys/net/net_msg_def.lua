
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
	[1] = "CLIENT_TEST",
	[2] = "CLIENT_TEST_RET",
	[3] = "REGISTER_SERVER_REQ",
	[4] = "REGISTER_SERVER_RET",
	[5] = "REGISTER_SERVER_BROADCAST",
	[6] = "SERVER_DISCONNECT",
	[7] = "REMOTE_CALL_REQ",
	[8] = "REMOTE_CALL_RET",

	[9] = "USER_LOGIN_REQ",
	[10] = "USER_LOGIN_RET",
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
		{ "session_id", _Int64 },
		{ "func_name", _String },
		{ "param", _String },
	},

	[MID.REMOTE_CALL_RET] =
	{
		{ "result", _Bool },
		{ "session_id", _Int64 },
		{ "param", _String },
	},


	----------------------------------------

	[MID.USER_LOGIN_REQ] =
	{
		{ "username", _String },
		{ "password", _String },
	},

	[MID.USER_LOGIN_RET] =
	{
		{ "result", _Int },
	},

}
