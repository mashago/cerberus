
#pragma once

#include <lua.hpp>
#include "world.h"
#include "pluto.h"

class LuaWorld : public World
{
public:
	static LuaWorld *Instance();

	virtual bool Init(int server_id, int server_type, const char *conf_file, const char *entry_file) override;

	virtual void HandleNewConnection(int64_t mailboxId, int32_t connType) override;
	virtual void HandleConnectToSuccess(int64_t mailboxId) override;
	virtual void HandleDisconnect(int64_t mailboxId) override;
	virtual void HandlePluto(Pluto &u) override;

	void HandleTimer(void *arg);
protected:
	LuaWorld();
	virtual ~LuaWorld();

	lua_State *m_L;
};
