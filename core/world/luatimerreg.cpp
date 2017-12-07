
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
	LuaWorld* luaworld = (LuaWorld*)luaL_checkudata(L, 1, "LuaWorldPtr");
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TBOOLEAN);

	int ms = lua_tointeger(L, 2);
	bool is_loop = lua_toboolean(L, 3);

	int64_t new_timer_index = luaworld->m_timerMgr->GetCurTimerIndex();
	// int64_t ret_timer_index = luaworld->m_timerMgr->AddTimer(ms, handler_timer, (void *)new_timer_index, is_loop);
	int64_t ret_timer_index = luaworld->m_timerMgr->AddTimer(ms, std::bind(&LuaWorld::HandleTimer, luaworld, std::placeholders::_1), (void *)new_timer_index, is_loop);

	lua_pushinteger(L, new_timer_index);
	lua_pushboolean(L, new_timer_index == ret_timer_index);

	return 2;
}

int del_timer_c(lua_State *L)
{
	LuaWorld* luaworld = (LuaWorld*)luaL_checkudata(L, 1, "LuaWorldPtr");
	luaL_checktype(L, 2, LUA_TNUMBER);
	int64_t timer_index = lua_tointeger(L, 2);

	bool ret = luaworld->m_timerMgr->DelTimer(timer_index);

	lua_pushboolean(L, ret);

	return 1;
}

void reg_timer_funcs(lua_State *L)
{
	lua_register(L, "add_timer_c", add_timer_c);
	lua_register(L, "del_timer_c", del_timer_c);
}

