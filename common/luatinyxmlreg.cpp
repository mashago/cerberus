
#include "luatinyxmlreg.h"
#include "tinyxml2.h"

int luatinyxmldoc_create(lua_State *L)
{
	tinyxml2::XMLDocument **d = (tinyxml2::XMLDocument**)lua_newuserdata(L, sizeof(tinyxml2::XMLDocument*));
	*d = new tinyxml2::XMLDocument();

	luaL_getmetatable(L, "TinyXMLDocLua");
	lua_setmetatable(L, -2);

	return 1;
}

int luatinyxmldoc_load_file(lua_State *L)
{
	tinyxml2::XMLDocument **d = (tinyxml2::XMLDocument**)luaL_checkudata(L, 1, "TinyXMLDocLua");
	luaL_argcheck(L, d != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TSTRING);

	const char* file_name = lua_tostring(L, -1);

	tinyxml2::XMLError ret = (*d)->LoadFile(file_name);

	lua_pushboolean(L, ret == tinyxml2::XMLError::XML_SUCCESS);

	return 1;
}

int luatinyxmldoc_first_child_element(lua_State *L)
{
	return 0;
}

int luatinyxmldoc_gc(lua_State *L)
{
	tinyxml2::XMLDocument **d = (tinyxml2::XMLDocument**)luaL_checkudata(L, 1, "TinyXMLDocLua");
	luaL_argcheck(L, d != NULL, 1, "invalid user data");

	if (d)
	{
		delete *d;
	}
	return 0;
}

// define constructor
static const luaL_Reg luatinyxmldoc_reg_construct_funcs[] =
{
	{ "create", luatinyxmldoc_create },
	{ NULL, NULL},
};

// define member functions
static const luaL_Reg luatinyxmldoc_reg_member_funcs[] = 
{
	{ "load_file", luatinyxmldoc_load_file },
	{ "first_child_element", luatinyxmldoc_first_child_element },
	{ "__gc", luatinyxmldoc_gc },
	{ NULL, NULL },
};

int luaopen_luatinyxmldoc(lua_State *L)
{
	luaL_newmetatable(L, "LuaTinyXMLDoc");

	lua_pushvalue(L, -1);

	lua_setfield(L, -2, "__index");

	luaL_setfuncs(L, luatinyxmldoc_reg_member_funcs, 0);

	luaL_newlib(L, luatinyxmldoc_reg_construct_funcs);

	return 1;
}

///////////////////////////////////////

int luatinyxmlele_first_child_element(lua_State *L)
{
	return 0;
}

// define member functions
static const luaL_Reg luatinyxmlele_reg_member_funcs[] = 
{
	{ "first_child_element", luatinyxmlele_first_child_element },
	{ NULL, NULL },
};

int luaopen_luatinyxmlele(lua_State *L)
{
	luaL_newmetatable(L, "LuaTinyXMLEle");

	lua_pushvalue(L, -1);

	lua_setfield(L, -2, "__index");

	luaL_setfuncs(L, luatinyxmlele_reg_member_funcs, 0);

	return 1;
}
