
#pragma once

#include <lua.hpp>
#include "world.h"
#include "pluto.h"

class LuaClient : public World
{
public:
	static LuaClient *Instance();

	virtual bool Init(int server_id, int server_type, const char *conf_file, const char *entry_file) override;

	virtual int HandlePluto(Pluto &u) override;
	virtual void HandleDisconnect(Mailbox *pmb) override;
	virtual void HandleConnectToSuccess(Mailbox *pmb) override;
	virtual void HandleNewConnection(Mailbox *pmb) override;
	virtual void HandleStdin(const char *buffer, int len);

	static void HandleTimer(void *arg);
private:
	LuaClient();
	virtual ~LuaClient();

	void HandleMsg(int64_t mailboxId, int msgId, Pluto &u);
	lua_State *m_L;
};

