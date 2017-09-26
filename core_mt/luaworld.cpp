
extern "C"
{
#include <string.h>
#include <lauxlib.h>
#include <lualib.h>
#include "lfs.h"
}
#include "util.h"
#include "logger.h"
#include "pluto.h"
#include "mailbox.h"
#include "luaworld.h"
#include "event_pipe.h"
#include "luanetworkreg.h"
#include "luanetwork.h"
#include "luatinyxmlreg.h"
#include "luamysqlmgrreg.h"
#include "luatimerreg.h"

LuaWorld::LuaWorld() : m_L(nullptr), m_luanetwork(nullptr), m_connIndex(0)
{
}

LuaWorld::~LuaWorld()
{
}

static int logger_c(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TNUMBER);
	luaL_checktype(L, 2, LUA_TSTRING);

	int type = lua_tointeger(L, 1);
	const char * str =  lua_tostring(L, 2);

	switch (type)
	{
		case LOG_TYPE_DEBUG:
		{
			LOG_RAW_STRING(LOG_TYPE_DEBUG, __FILE__, __FUNCTION__, 0,  str);
			break;
		}
		case LOG_TYPE_INFO:
		{
			LOG_RAW_STRING(LOG_TYPE_INFO, __FILE__, __FUNCTION__, 0, str);
			break;
		}
		case LOG_TYPE_WARN:
		{
			LOG_RAW_STRING(LOG_TYPE_WARN, __FILE__, __FUNCTION__, 0, str);
			break;
		}
		case LOG_TYPE_ERROR:
		{
			LOG_RAW_STRING(LOG_TYPE_ERROR, __FILE__, __FUNCTION__, 0, str);
			break;
		}
	};
	
	return 0;
}

static int get_time_ms_c(lua_State *L)
{
	struct timeval tv;    
	gettimeofday(&tv, NULL);
	double time_ms = tv.tv_sec * 1000.0 + tv.tv_usec / 1000.0;
	lua_pushnumber(L, time_ms);

	return 1;
}

bool LuaWorld::Init(int server_id, int server_type, const char *conf_file, const char *entry_file)
{
	m_luanetwork = new LuaNetwork(this);

	m_L = luaL_newstate();
	if (!m_L)
	{
		return false;
	}

	// register lib
	const luaL_Reg lua_reg_libs[] = 
	{
		{ "base", luaopen_base },
		{ LUA_TABLIBNAME, luaopen_table },
		{ LUA_IOLIBNAME, luaopen_io },
		{ LUA_OSLIBNAME, luaopen_os },
		// { LUA_BITLIBNAME, luaopen_bit32 },
		{ LUA_COLIBNAME, luaopen_coroutine },
		{ LUA_MATHLIBNAME, luaopen_math },
		{ LUA_DBLIBNAME, luaopen_debug },
		{ LUA_LOADLIBNAME, luaopen_package },
		{ LUA_STRLIBNAME, luaopen_string },
		{ "LuaNetwork", luaopen_luanetwork },
		{ "LuaTinyXMLDoc", luaopen_luatinyxmldoc },
		{ "LuaTinyXMLEle", luaopen_luatinyxmlele },
		{ "LuaMysqlMgr", luaopen_luamysqlmgr },
		{ "lfs", luaopen_lfs },
		{ NULL, NULL },
	};

	for (const luaL_Reg *libptr = lua_reg_libs; libptr->func; ++libptr)
	{
		luaL_requiref(m_L, libptr->name, libptr->func, 1);
		lua_pop(m_L, 1);
	}

	// register timer function
	reg_timer_funcs(m_L);

	// register logger for lua
	lua_register(m_L, "logger_c", logger_c);
	lua_register(m_L, "get_time_ms_c", get_time_ms_c);
	

	// set global params
	lua_pushinteger(m_L, server_id);
	lua_setglobal(m_L, "g_server_id");
	lua_pushinteger(m_L, server_type);
	lua_setglobal(m_L, "g_server_type");
	lua_pushstring(m_L, conf_file);
	lua_setglobal(m_L, "g_conf_file");
	lua_pushstring(m_L, entry_file);
	lua_setglobal(m_L, "g_entry_file");

	// push this to lua
	lua_pushlightuserdata(m_L, (void *)this);
	luaL_newmetatable(m_L, "LuaWorldPtr");
	lua_setmetatable(m_L, -2);
	lua_setglobal(m_L, "g_luaworld_ptr");

	if (luaL_dofile(m_L, "../script/main.lua"))
	{
		const char * msg = lua_tostring(m_L, -1);
		LOG_ERROR("msg=%s", msg);
		return false;
	}

	return true;
}

void LuaWorld::HandleNewConnection(int64_t mailboxId, int32_t connType)
{
	LOG_DEBUG("mailboxId=%ld connType=%d", mailboxId, connType);

	lua_getglobal(m_L, "ccall_new_connection");
	lua_pushnumber(m_L, mailboxId);
	lua_pushinteger(m_L, connType);
	lua_call(m_L, 2, 0);
}

void LuaWorld::HandleDisconnect(int64_t mailboxId)
{
	LOG_DEBUG("mailboxId=%ld", mailboxId);

	lua_getglobal(m_L, "ccall_disconnect_handler");
	lua_pushnumber(m_L, mailboxId);
	lua_call(m_L, 1, 0);
}

void LuaWorld::HandleConnectToSuccess(int64_t mailboxId)
{
	LOG_DEBUG("mailboxId=%ld", mailboxId);

	lua_getglobal(m_L, "ccall_connect_to_success_handler");
	lua_pushnumber(m_L, mailboxId);
	lua_call(m_L, 1, 0);
}

void LuaWorld::HandleMsg(Pluto &u)
{
	int64_t mailboxId = u.GetMailboxId();
	int msgId = u.ReadMsgId();
	// LOG_DEBUG("mailboxId=%ld msgId=%d", mailboxId, msgId);

	m_luanetwork->SetRecvPluto(&u);
	lua_getglobal(m_L, "ccall_recv_msg_handler");
	lua_pushnumber(m_L, mailboxId);
	lua_pushinteger(m_L, msgId);
	lua_call(m_L, 2, 0);
}

void LuaWorld::HandleConnectToRet(int64_t connIndex, int64_t mailboxId)
{
	LOG_DEBUG("connIndex=%ld mailboxId=%ld", connIndex, mailboxId);

	lua_getglobal(m_L, "ccall_connect_to_ret_handler");
	lua_pushnumber(m_L, connIndex);
	lua_pushnumber(m_L, mailboxId);
	lua_call(m_L, 2, 0);
}

void LuaWorld::HandleHttpResponse(int64_t session_id, int response_code, const char *content, int content_len)
{
	// LOG_DEBUG("session_id=%ld response_code=%d content_len=%d content=%s", session_id, response_code, content_len, content);

	lua_getglobal(m_L, "ccall_http_response_handler");
	lua_pushnumber(m_L, session_id);
	lua_pushinteger(m_L, response_code);
	if (content)
	{
		lua_pushlstring(m_L, content, content_len);
	}
	else
	{
		lua_pushstring(m_L, "");
	}
	lua_call(m_L, 3, 0);
}

void LuaWorld::HandleTimer(void *arg)
{
	int64_t timer_index = (int64_t)arg;
	// LOG_DEBUG("timer_index=%ld", timer_index);

	lua_getglobal(m_L, "ccall_timer_handler");
	lua_pushinteger(m_L, timer_index);
	lua_call(m_L, 1, 0);
}

//////////////////////////////////////////////

// send a eventnode to net, return a connect index for connect to ret event
int64_t LuaWorld::ConnectTo(const char* ip, unsigned int port)
{
	EventNodeConnectToReq *node = new EventNodeConnectToReq;
	sprintf(node->ip, "%s", ip);
	node->port = port;
	node->ext = ++m_connIndex;
	SendEvent(node);
	return m_connIndex;
}

void LuaWorld::SendPluto(Pluto *pu)
{
	EventNodeMsg *node = new EventNodeMsg;
	node->pu = pu;
	SendEvent(node);
}

void LuaWorld::CloseMailbox(int64_t mailboxId)
{
	EventNodeDisconnect *node = new EventNodeDisconnect;
	node->mailboxId = mailboxId;
	SendEvent(node);
}

bool LuaWorld::HttpRequest(const char *url, int64_t session_id, int request_type, const char *post_data, int post_data_len)
{
	EventNodeHttpReq *node = new EventNodeHttpReq;
	int len = strlen(url) + 1;
	char *url_ptr = new char[len];
	memcpy(url_ptr, url, len);

	char *post_data_ptr = NULL;
	if (post_data_len == 0)
	{
		post_data_ptr = new char[post_data_len];
		memcpy(post_data_ptr, post_data, post_data_len);
	}

	node->url = url_ptr;
	node->session_id = session_id;
	node->request_type = request_type;
	node->post_data = post_data_ptr;
	node->post_data_len = post_data_len;
	SendEvent(node);

	return true;
}

