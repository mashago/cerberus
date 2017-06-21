
#pragma once

#include <lua.hpp>
#include "world.h"
#include "pluto.h"

class LuaWorld : public World
{
public:
	static LuaWorld *Instance();

	virtual bool Init(int server_id, int server_type, const char *conf_file, const char *entry_file) override;

	virtual int HandlePluto(Pluto &u) override;
	virtual void HandleDisconnect(Mailbox *pmb) override;
	virtual void HandleConnectToSuccess(Mailbox *pmb) override;
	virtual void HandleNewConnection(Mailbox *pmb) override;

	virtual void HandleTimer(void *arg);
protected:
	LuaWorld();
	virtual ~LuaWorld();

	void HandleMsg(int64_t mailboxId, int msgId, Pluto &u);
	lua_State *m_L;
};

