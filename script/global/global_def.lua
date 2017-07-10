
ServerType =
{
	NULL 			= 0,
	ROUTER 			= 1,
	SCENE 			= 2,
	DB 				= 3,
	BRIDGE 			= 4,
	LOGIN 			= 5,
	PUBLIC 			= 6,
	CROSS 			= 7,
	PAY 			= 8,
	CHAT 			= 9,
}

ConnType =
{
	NULL 	= 0,
	UNTRUST = 1,
	TRUST 	= 2,
}

ErrorCode =
{
	SUCCESS 						= 1,
	SYS_ERROR 						= 2,
	AREA_NOT_OPEN 					= 3,

	USER_LOGIN_FAIL 				= 1001,
	USER_LOGIN_PASSWORD_MISMATCH 	= 1002,
	USER_LOGIN_DUPLICATE_LOGIN 		= 1003,

	CREATE_ROLE_FAIL 				= 1101,
	CREATE_ROLE_NUM_MAX 			= 1102,
	CREATE_ROLE_DUPLICATE_NAME 		= 1103,

	DELETE_ROLE_FAIL 				= 1201,

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
