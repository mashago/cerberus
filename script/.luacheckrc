std = "lua53"
globals = {
"_Null",
"_Byte",
"_Bool",
"_Int",
"_Float",
"_Short",
"_Int64",
"_String",
"_Struct",
"_StructString",

"_ByteArray",
"_BoolArray",
"_IntArray",
"_FloatArray",
"_ShortArray",
"_Int64Array",
"_StringArray",
"_StructArray",

"DataStructDef",
"MSG_DEF_MAP",
"RAW_MID",

"ccall_recv_msg_handler",
"ccall_disconnect_handler",
"ccall_connect_to_ret_handler",
"ccall_connect_to_success_handler",
"ccall_new_connection",
"ccall_http_response_handler",
"ccall_timer_handler",
"ccall_stdin_handler",

"g_net_event_server_connect",
"g_net_event_server_disconnect",
"g_net_event_client_disconnect",
"g_net_event_client_msg",
}

ignore = {
	"111",
	"212",
	"213",
	"611",
	"612",
	"613",
	"614",
	"621",
	"631",
}

exclude_files = {
	"hotfix"
}
