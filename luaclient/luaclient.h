
#pragma once

#include <lua.hpp>
#include "luaworld.h"
#include "pluto.h"

class LuaClient : public LuaWorld
{
public:
	static LuaClient *Instance();

	virtual bool Init(int server_id, int server_type, const char *conf_file, const char *entry_file) override;

	// virtual int HandlePluto(Pluto &u) override;
	virtual void HandleDisconnect(Mailbox *pmb) override;
	// virtual void HandleConnectToSuccess(Mailbox *pmb) override;
	virtual void HandleNewConnection(Mailbox *pmb) override;
	virtual void HandleStdin(const char *buffer, int len) override;

	// virtual void HandleTimer(void *arg) override;
protected:
	LuaClient();
	virtual ~LuaClient();

	// void HandleMsg(int64_t mailboxId, int msgId, Pluto &u);
};

