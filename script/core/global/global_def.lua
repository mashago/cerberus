
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

ServerType =
{
	NULL 			= 0,
	LOGIN 			= 1,
	DB 				= 2,

	MASTER			= 3,
	BRIDGE 			= 4,
	GATE 			= 5,
	BASE 			= 6,
	CELL 			= 7,
	PUBLIC 			= 8,

}

ConnType =
{
	NULL 	= 0,
	UNTRUST = 1,
	TRUST 	= 2,
}

DBType = 
{
	LOGIN = 1,
	GAME  = 2,
}

ServiceConnectStatus =
{
	DISCONNECT 	= 1,
	CONNECTING 	= 2,
	CONNECTED 	= 3,
}

ErrorCode =
{
	SUCCESS 						= 1,
	SYS_ERROR 						= 2,
	AREA_NOT_OPEN 					= 3,
	ROLE_NOT_EXISTS					= 4,

	USER_LOGIN_FAIL 				= 1001,
	USER_LOGIN_PASSWORD_MISMATCH 	= 1002,
	USER_LOGIN_DUPLICATE_LOGIN 		= 1003,

	CREATE_ROLE_FAIL 				= 1101,
	CREATE_ROLE_NUM_MAX 			= 1102,
	CREATE_ROLE_DUPLICATE_NAME 		= 1103,

	DELETE_ROLE_FAIL 				= 1201,
	DELETE_ROLE_ONLINE 				= 1202,

	SELECT_ROLE_FAIL 				= 1301,
	SELECT_ROLE_DUPLICATE_LOGIN 	= 1302,

	ROLE_ENTER_FAIL 				= 1401,

	REGISTER_SERVER_FAIL 			= 600001,
	REGISTER_SERVER_UNTRUST 		= 600002,
	RPC_FAIL 						= 600003,
	REGISTER_AREA_DUPLICATE			= 600004,
}

ErrorCodeText = {}
local function create_error_code_text()
	for k, v in pairs(ErrorCode) do
		ErrorCodeText[v] = k
	end
end
create_error_code_text()
