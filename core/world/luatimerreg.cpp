
extern "C"
{
#include <lauxlib.h>
#include <lualib.h>
}
#include <functional>
#include "logger.h"
#include "luatimerreg.h"
#include "timermgr.h"
#include "luaworld.h"

int add_timer_c(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TNUMBER);
	luaL_checktype(L, 2, LUA_TBOOLEAN);

	int ms = (int)lua_tointeger(L, 1);
	bool is_loop = (bool)lua_toboolean(L, 2);

	lua_getglobal(L, "g_luaworld_ptr");
	LuaWorld **ptr = (LuaWorld **)lua_touserdata(L, -1);
	LuaWorld *luaworld = *ptr;
	lua_pop(L, 1);

	TimerMgr *timerMgr = luaworld->GetTimerMgr();

	int64_t new_timer_index = timerMgr->GetCurTimerIndex();
	int64_t ret_timer_index = timerMgr->AddTimer(ms, std::bind(&LuaWorld::HandleTimer, luaworld, std::placeholders::_1, std::placeholders::_2), (void *)new_timer_index, is_loop);

	lua_pushinteger(L, new_timer_index);
	lua_pushboolean(L, new_timer_index == ret_timer_index);

	return 2;
}

int del_timer_c(lua_State *L)
{
	luaL_checktype(L, 1, LUA_TNUMBER);
	int64_t timer_index = lua_tointeger(L, 1);

	lua_getglobal(L, "g_luaworld_ptr");
	LuaWorld **ptr = (LuaWorld **)lua_touserdata(L, -1);
	LuaWorld *luaworld = *ptr;
	lua_pop(L, 1);

	TimerMgr *timerMgr = luaworld->GetTimerMgr();

	bool ret = timerMgr->DelTimer(timer_index);

	lua_pushboolean(L, ret);

	return 1;
}

void reg_timer_funcs(lua_State *L)
{
	lua_register(L, "add_timer_c", add_timer_c);
	lua_register(L, "del_timer_c", del_timer_c);
}

