
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "logger.h"
#include "luaworld.h"
#include "mailbox.h"
#include "luanetworkreg.h"
#include "luanetwork.h"
#include "luatinyxmlreg.h"
#include "luamysqlmgrreg.h"
#include "luatimerreg.h"

LuaWorld* LuaWorld::Instance()
{
	static LuaWorld *instance = new LuaWorld();
	return instance;
}

LuaWorld::LuaWorld() : m_L(nullptr)
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
			// LOG_DEBUG("%s", str);
			_logcore(LOG_TYPE_DEBUG, __FILE__, __FUNCTION__, 0, "%s", str);
			break;
		}
		case LOG_TYPE_INFO:
		{
			// LOG_INFO("%s", str);
			_logcore(LOG_TYPE_INFO, __FILE__, __FUNCTION__, 0, "%s", str);
			break;
		}
		case LOG_TYPE_WARN:
		{
			// LOG_WARN("%s", str);
			_logcore(LOG_TYPE_WARN, __FILE__, __FUNCTION__, 0, "%s", str);
			break;
		}
		case LOG_TYPE_ERROR:
		{
			// LOG_ERROR("%s", str);
			_logcore(LOG_TYPE_ERROR, __FILE__, __FUNCTION__, 0, "%s", str);
			break;
		}
	};
	
	return 0;
}

bool LuaWorld::Init(int server_id, int server_type, const char *conf_file, const char *entry_file)
{
	LuaNetwork::Instance()->SetWorld(this);

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
		{ LUA_BITLIBNAME, luaopen_bit32 },
		{ LUA_COLIBNAME, luaopen_coroutine },
		{ LUA_MATHLIBNAME, luaopen_math },
		{ LUA_DBLIBNAME, luaopen_debug },
		{ LUA_LOADLIBNAME, luaopen_package },
		{ LUA_STRLIBNAME, luaopen_string },
		{ "LuaNetwork", luaopen_luanetwork },
		{ "LuaTinyXMLDoc", luaopen_luatinyxmldoc },
		{ "LuaTinyXMLEle", luaopen_luatinyxmlele },
		{ "LuaMysqlMgr", luaopen_luamysqlmgr },
		{ NULL, NULL },
	};

	for (const luaL_Reg *libptr = lua_reg_libs; libptr->func; ++libptr)
	{
		luaL_requiref(m_L, libptr->name, libptr->func, 1);
		lua_pop(m_L, 1);
	}

	// register timer function
	reg_timer_funcs(m_L, this);

	// register logger for lua
	lua_register(m_L, "logger_c", logger_c);
	

	// set global params
	lua_pushinteger(m_L, server_id);
	lua_setglobal(m_L, "g_server_id");
	lua_pushinteger(m_L, server_type);
	lua_setglobal(m_L, "g_server_type");
	lua_pushstring(m_L, conf_file);
	lua_setglobal(m_L, "g_conf_file");
	lua_pushstring(m_L, entry_file);
	lua_setglobal(m_L, "g_entry_file");

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
	LOG_DEBUG("mailboxId=%ld msgId=%d", mailboxId, msgId);

	LuaNetwork::Instance()->SetRecvPluto(&u);
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

void LuaWorld::HandleTimer(void *arg)
{
	int64_t timer_index = (int64_t)arg;
	// LOG_DEBUG("timer_index=%ld", timer_index);

	lua_getglobal(m_L, "ccall_timer_handler");
	lua_pushinteger(m_L, timer_index);
	lua_call(m_L, 1, 0);
}

//////////////////////////////////////////////

int64_t LuaWorld::ConnectTo(const char* ip, unsigned int port)
{
	static int64_t connIndex = 0;
	
	EventNodeConnectToReq *node = new EventNodeConnectToReq;
	sprintf(node->ip, "%s", ip);
	node->port = port;
	node->ext = ++connIndex;
	SendEvent(node);
	return connIndex;
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

