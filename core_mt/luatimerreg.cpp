
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include "logger.h"
#include "luatimerreg.h"
#include "timermgr.h"
#include "luaworld.h"

static LuaWorld *s_luaworld = nullptr;

void handler_timer(void *arg)
{
	if (s_luaworld)
	{
		// LOG_DEBUG("arg=%ld", (int64_t)arg);
		s_luaworld->HandleTimer(arg);
	}
}

int add_timer_c(lua_State *L)
{
	int ms = lua_tointeger(L, 1);
	bool is_loop = lua_toboolean(L, 2);

	luaL_checktype(L, 1, LUA_TNUMBER);
	luaL_checktype(L, 2, LUA_TBOOLEAN);

	int64_t new_timer_index = TimerMgr::GetCurTimerIndex() + 1;
	// int64_t ret_timer_index = TimerMgr::AddTimer(ms, LuaWorld::HandleTimer, (void *)new_timer_index, is_loop);
	int64_t ret_timer_index = TimerMgr::AddTimer(ms, handler_timer, (void *)new_timer_index, is_loop);

	lua_pushinteger(L, new_timer_index);
	lua_pushboolean(L, new_timer_index == ret_timer_index);

	return 2;
}

int del_timer_c(lua_State *L)
{
	int64_t timer_index = lua_tointeger(L, 1);
	luaL_checktype(L, 1, LUA_TNUMBER);

	bool ret = TimerMgr::DelTimer(timer_index);

	lua_pushboolean(L, ret);

	return 1;
}

void reg_timer_funcs(lua_State *L, LuaWorld *ptr)
{
	s_luaworld = ptr;
	lua_register(L, "add_timer_c", add_timer_c);
	lua_register(L, "del_timer_c", del_timer_c);
}

