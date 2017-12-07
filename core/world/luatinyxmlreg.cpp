
#include <stdint.h>
#include "logger.h"
#include "luatinyxmlreg.h"
#include "tinyxml2.h"

int luatinyxmldoc_create(lua_State *L)
{
	tinyxml2::XMLDocument **p_doc = (tinyxml2::XMLDocument**)lua_newuserdata(L, sizeof(tinyxml2::XMLDocument**));
	*p_doc = new tinyxml2::XMLDocument();

	luaL_getmetatable(L, "LuaTinyXMLDoc");
	lua_setmetatable(L, -2);

	return 1;
}

// param1: file_name_str
// return: bool
int luatinyxmldoc_load_file(lua_State *L)
{
	tinyxml2::XMLDocument **p_doc = (tinyxml2::XMLDocument**)luaL_checkudata(L, 1, "LuaTinyXMLDoc");
	luaL_argcheck(L, p_doc != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TSTRING);

	const char* file_name = lua_tostring(L, -1);

	tinyxml2::XMLError ret = (*p_doc)->LoadFile(file_name);

	lua_pushboolean(L, ret == tinyxml2::XMLError::XML_SUCCESS);

	return 1;
}

// param: ele_name or nil
int luatinyxmldoc_first_child_element(lua_State *L)
{
	tinyxml2::XMLDocument **p_doc = (tinyxml2::XMLDocument**)luaL_checkudata(L, 1, "LuaTinyXMLDoc");
	luaL_argcheck(L, p_doc != NULL, 1, "invalid user data");

	// get element
	tinyxml2::XMLElement *ele = nullptr;
	int args_count = lua_gettop(L);
	const char *ele_name = NULL;
	if (args_count > 1)
	{
		luaL_checktype(L, -1, LUA_TSTRING);
		ele_name = lua_tostring(L, -1);
	}
	ele = (*p_doc)->FirstChildElement(ele_name);

	// push element
	if (ele)
	{
		tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement **)lua_newuserdata(L, sizeof(tinyxml2::XMLElement **));
		*p_ele = ele;
		luaL_getmetatable(L, "LuaTinyXMLEle");
		lua_setmetatable(L, -2);
	}
	else
	{
		lua_pushnil(L);
	}

	return 1;
}

int luatinyxmldoc_gc(lua_State *L)
{
	LOG_DEBUG("do gc");
	tinyxml2::XMLDocument **p_doc = (tinyxml2::XMLDocument**)luaL_checkudata(L, 1, "LuaTinyXMLDoc");
	luaL_argcheck(L, p_doc != NULL, 1, "invalid user data");

	if (p_doc)
	{
		delete *p_doc;
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
	tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement**)luaL_checkudata(L, 1, "LuaTinyXMLEle");
	luaL_argcheck(L, p_ele != NULL, 1, "invalid user data");

	// get element
	tinyxml2::XMLElement *ele = nullptr;
	int args_count = lua_gettop(L);
	const char *ele_name = NULL;
	if (args_count > 1)
	{
		luaL_checktype(L, -1, LUA_TSTRING);
		ele_name = lua_tostring(L, -1);
	}
	ele = (*p_ele)->FirstChildElement(ele_name);

	// push element
	if (ele)
	{
		tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement **)lua_newuserdata(L, sizeof(tinyxml2::XMLElement **));
		*p_ele = ele;
		luaL_getmetatable(L, "LuaTinyXMLEle");
		lua_setmetatable(L, -2);
	}
	else
	{
		lua_pushnil(L);
	}

	return 1;
}

int luatinyxmlele_next_sibling_element(lua_State *L)
{
	tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement**)luaL_checkudata(L, 1, "LuaTinyXMLEle");
	luaL_argcheck(L, p_ele != NULL, 1, "invalid user data");

	// get element
	tinyxml2::XMLElement *ele = nullptr;
	int args_count = lua_gettop(L);
	const char *ele_name = NULL;
	if (args_count > 1)
	{
		luaL_checktype(L, -1, LUA_TSTRING);
		ele_name = lua_tostring(L, -1);
	}
	ele = (*p_ele)->NextSiblingElement(ele_name);

	// push element
	if (ele)
	{
		tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement **)lua_newuserdata(L, sizeof(tinyxml2::XMLElement **));
		*p_ele = ele;
		luaL_getmetatable(L, "LuaTinyXMLEle");
		lua_setmetatable(L, -2);
	}
	else
	{
		lua_pushnil(L);
	}

	return 1;
}

int luatinyxmlele_int_attribute(lua_State *L)
{
	tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement**)luaL_checkudata(L, 1, "LuaTinyXMLEle");
	luaL_argcheck(L, p_ele != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TSTRING);

	int attr = (*p_ele)->IntAttribute(lua_tostring(L, -1));

	lua_pushinteger(L, attr);

	return 1;
}

int luatinyxmlele_bool_attribute(lua_State *L)
{
	tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement**)luaL_checkudata(L, 1, "LuaTinyXMLEle");
	luaL_argcheck(L, p_ele != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TSTRING);

	bool attr = (*p_ele)->BoolAttribute(lua_tostring(L, -1));

	lua_pushboolean(L, attr);

	return 1;
}

int luatinyxmlele_string_attribute(lua_State *L)
{
	tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement**)luaL_checkudata(L, 1, "LuaTinyXMLEle");
	luaL_argcheck(L, p_ele != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TSTRING);

	const char *attr = (*p_ele)->Attribute(lua_tostring(L, -1));

	lua_pushstring(L, attr);

	return 1;
}

int luatinyxmlele_double_attribute(lua_State *L)
{
	tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement**)luaL_checkudata(L, 1, "LuaTinyXMLEle");
	luaL_argcheck(L, p_ele != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TSTRING);

	double attr = (*p_ele)->DoubleAttribute(lua_tostring(L, -1));

	lua_pushnumber(L, attr);

	return 1;
}

int luatinyxmlele_int64_attribute(lua_State *L)
{
	tinyxml2::XMLElement **p_ele = (tinyxml2::XMLElement**)luaL_checkudata(L, 1, "LuaTinyXMLEle");
	luaL_argcheck(L, p_ele != NULL, 1, "invalid user data");

	luaL_checktype(L, -1, LUA_TSTRING);

	int64_t attr = (*p_ele)->Int64Attribute(lua_tostring(L, -1));

	lua_pushinteger(L, attr);

	return 1;
}

// define member functions
static const luaL_Reg luatinyxmlele_reg_member_funcs[] = 
{
	{ "first_child_element", luatinyxmlele_first_child_element },
	{ "next_sibling_element", luatinyxmlele_next_sibling_element },
	{ "int_attribute", luatinyxmlele_int_attribute },
	{ "bool_attribute", luatinyxmlele_bool_attribute },
	{ "string_attribute", luatinyxmlele_string_attribute },
	{ "double_attribute", luatinyxmlele_double_attribute },
	{ "int64_attribute", luatinyxmlele_int64_attribute },
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
