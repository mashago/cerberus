
local M = {}

-- data define
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

M.ServerType =
{
	NULL 			= 0,
	LOGIN 			= 1,
	DB 				= 2,

	MASTER			= 3,
	BRIDGE 			= 4,
	GATE 			= 5,
	SCENE 			= 6,

	PUBLIC 			= 8,
}

M.ServerTypeName = { }
for k, v in pairs(M.ServerType) do
	M.ServerTypeName[v] = k
end

M.TrustIPList =
{
	["127.0.0.1"] = true,
}

M.ConnType =
{
	UNTRUST = 1,
	TRUST 	= 2,
}

M.DBType = 
{
	LOGIN = 1,
	GAME  = 2,
}

M.ServiceConnectStatus =
{
	DISCONNECT 		= 1,
	DISCONNECTING 	= 2,
	CONNECTING 		= 3,
	CONNECTED 		= 4,
}

M.HttpRequestType =
{
	GET = 1,
	POST = 2,
}

M.MAILBOX_ID_NIL = 0

return M
