
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

LuaWorld::LuaWorld() : _L(nullptr)
{
}

LuaWorld::~LuaWorld()
{
}

bool LuaWorld::Init(int server_id, int server_type, const char *entry_file)
{
	LuaNetwork::Instance()->SetNetService(m_net);

	_L = luaL_newstate();
	if (!_L)
	{
		return false;
	}

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
		{ NULL, NULL },
	};

	for (const luaL_Reg *libptr = lua_reg_libs; libptr->func; ++libptr)
	{
		luaL_requiref(_L, libptr->name, libptr->func, 1);
		lua_pop(_L, 1);
	}

	lua_pushinteger(_L, server_id);
	lua_setglobal(_L, "g_server_id");
	lua_pushinteger(_L, server_type);
	lua_setglobal(_L, "g_server_type");
	lua_pushstring(_L, entry_file);
	lua_setglobal(_L, "g_entry_file");

	if (luaL_dofile(_L, "../script/main.lua"))
	{
		const char * msg = lua_tostring(_L, -1);
		LOG_ERROR("msg=%s", msg);
		return false;
	}

	return true;
}

int LuaWorld::HandlePluto(Pluto &u)
{
	// TODO set pluto into a luanetwork

	Mailbox *pmb = u.GetMailbox();
	int mailboxId = pmb->GetMailboxId();
	int msgId = u.ReadMsgId();

	handleMsg(mailboxId, msgId, u);

	return 0;
}

void LuaWorld::handleMsg(int mailboxId, int msgId, Pluto &u)
{
	LuaNetwork::Instance()->SetRecvPluto(&u);
	lua_getglobal(_L, "ccall_net_recv_msg_handler");
	lua_pushinteger(_L, mailboxId);
	lua_pushinteger(_L, msgId);
	lua_call(_L, 2, 0);
}

void LuaWorld::HandleDisconnect(Mailbox *pmb)
{
}

void LuaWorld::HandleConnectToSuccess(Mailbox *pmb)
{
}

