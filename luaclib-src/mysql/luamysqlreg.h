
#pragma once

#include <lua.hpp>

#ifdef _WIN32
#define CERBERUS_LUA_EXPORT __declspec (dllexport)
#else
#define CERBERUS_LUA_EXPORT
#endif

CERBERUS_LUA_EXPORT int luaopen_cerberus_mysql(lua_State *L);

