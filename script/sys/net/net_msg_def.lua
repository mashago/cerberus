
_Byte = 1
_Bool = 2
_Int = 3
_Float = 4
_LongLong = 5
_String = 6
_Struct = 7
_Short = 8

_ByteArray = 11
_BoolArray = 12
_IntArray = 13
_FloatArray = 14
_LongLongArray = 15
_StringArray = 16
_StructArray = 17
_ShortArray = 18

MID = {}
MID._id_name_map = 
{
	[1] = "CLIENT_TEST",
	[2] = "CLIENT_TEST_RET",
}

local function create_msg_id_array()
	for k, v in pairs(MID._id_name_map) do
		MID[v] = k
	end
end
create_msg_id_array()


MSG_DEF_MAP = {}
MSG_DEF_MAP =
{
	[MID.CLIENT_TEST] =
	{
		{ "client_time", _Int },
		{ "client_data", _String },
	},

	[MID.CLIENT_TEST_RET] =
	{
		{ "server_time", _Int },
		{ "server_data", _String },
	},
}
