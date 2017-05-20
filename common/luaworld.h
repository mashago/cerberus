
#pragma once

#include <lua.hpp>
#include "world.h"
#include "pluto.h"

class LuaWorld : public World
{
public:
	LuaWorld();
	virtual ~LuaWorld();

	virtual bool Init(int server_id, int server_type, const char *entry_file_name) override;

	virtual int HandlePluto(Pluto &u) override;
	virtual void HandleDisconnect(Mailbox *pmb) override;
	virtual void HandleConnectToSuccess(Mailbox *pmb) override;
private:
	void handleMsg(int mailboxId, int msgId, Pluto &u);
	lua_State *m_L;
};

