
#pragma once

#include <lua.hpp>
#include "luaworld.h"

class LuaClient : public LuaWorld
{
public:
	LuaClient();
	virtual ~LuaClient();

	virtual void HandleNewConnection(int64_t mailboxId, int32_t connType, const char *ip, int port) override;
	virtual void HandleStdin(const char *buffer) override;
};

