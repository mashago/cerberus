
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

