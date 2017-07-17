
#pragma once

#include <lua.hpp>
#include "luaworld.h"
#include "pluto.h"

class LuaClient : public LuaWorld
{
public:
	static LuaClient *Instance();

	// virtual bool Init(int server_id, int server_type, const char *conf_file, const char *entry_file) override;

	virtual void HandleNewConnection(Mailbox *pmb) override;
	virtual void HandleStdin(const char *buffer, int len) override;

protected:
	LuaClient();
	virtual ~LuaClient();
};

