
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "logger.h"
#include "luaworld.h"
#include "mailbox.h"

LuaWorld::LuaWorld() : _L(nullptr)
{
}

LuaWorld::~LuaWorld()
{
}

bool LuaWorld::Init(int server_id, int server_type, const char *entry_file_name)
{

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
	lua_pushstring(_L, entry_file_name);
	lua_setglobal(_L, "g_entry_file_name");

	return true;
}

int LuaWorld::HandlePluto(Pluto &u)
{
	return 0;
}

void LuaWorld::HandleDisconnect(Mailbox *pmb)
{
}

void LuaWorld::HandleConnectToSuccess(Mailbox *pmb)
{
}

