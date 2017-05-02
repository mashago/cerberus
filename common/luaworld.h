
#ifndef __LUAWORLD_H__
#define __LUAWORLD_H__

#include <lua.h>
#include "world.h"
#include "pluto.h"

class LuaWorld : public World
{
public:
	LuaWorld();
	virtual ~LuaWorld();

	virtual bool init(int server_id, int server_type, char * entry_file_name);

	virtual int HandlePluto(Pluto &u) = 0;
	virtual bool CheckPluto(Pluto &u);
	virtual void HandleDisconnect(Mailbox *pmb) = 0;
	virtual void HandleConnectToSuccess(Mailbox *pmb) = 0;
private:
	lua_State *_L;
};

#endif
