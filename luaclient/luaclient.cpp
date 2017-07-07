
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "logger.h"
#include "luaclient.h"
#include "mailbox.h"
#include "luanetworkreg.h"
#include "luanetwork.h"
#include "luatinyxmlreg.h"
#include "luatimerreg.h"

LuaClient* LuaClient::Instance()
{
	static LuaClient *instance = new LuaClient();
	return instance;
}

LuaClient::LuaClient()
{
}

LuaClient::~LuaClient()
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

bool LuaClient::Init(int server_id, int server_type, const char *conf_file, const char *entry_file)
{
	LuaNetwork::Instance()->SetNetService(m_net);

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

/*
int LuaClient::HandlePluto(Pluto &u)
{
	Mailbox *pmb = u.GetMailbox();
	LOG_DEBUG("mailboxId=%ld", pmb->GetMailboxId());
	int64_t mailboxId = pmb->GetMailboxId();
	int msgId = u.ReadMsgId();

	HandleMsg(mailboxId, msgId, u);

	return 0;
}
*/

/*
void LuaClient::HandleMsg(int64_t mailboxId, int msgId, Pluto &u)
{
	LuaNetwork::Instance()->SetRecvPluto(&u);
	lua_getglobal(m_L, "ccall_recv_msg_handler");
	lua_pushnumber(m_L, mailboxId);
	lua_pushinteger(m_L, msgId);
	lua_call(m_L, 2, 0);
}
*/

void LuaClient::HandleDisconnect(Mailbox *pmb)
{
	LOG_DEBUG("mailboxId=%ld", pmb->GetMailboxId());

	/*
	lua_getglobal(m_L, "ccall_disconnect_handler");
	lua_pushnumber(m_L, pmb->GetMailboxId());
	lua_call(m_L, 1, 0);
	*/
}

/*
void LuaClient::HandleConnectToSuccess(Mailbox *pmb)
{
	LOG_DEBUG("mailboxId=%ld", pmb->GetMailboxId());

	lua_getglobal(m_L, "ccall_connect_to_success_handler");
	lua_pushnumber(m_L, pmb->GetMailboxId());
	lua_call(m_L, 1, 0);
}
*/

void LuaClient::HandleNewConnection(Mailbox *pmb)
{
	// do nothing
}

void LuaClient::HandleStdin(const char *buffer, int len)
{
	lua_getglobal(m_L, "ccall_stdin_handler");
	lua_pushlstring(m_L, buffer, len);
	lua_call(m_L, 1, 0);
}

/*
void LuaClient::HandleTimer(void *arg)
{
	int64_t timer_index = (int64_t)arg;
	// LOG_DEBUG("timer_index=%ld", timer_index);

	LuaClient *pInstance = Instance();
	lua_getglobal(pInstance->m_L, "ccall_timer_handler");
	lua_pushinteger(pInstance->m_L, timer_index);
	lua_call(pInstance->m_L, 1, 0);
}
*/

