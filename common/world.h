
#ifndef __WORLD_H__
#define __WORLD_H__

#include "pluto.h"

class World
{
public:
	World();
	virtual ~World();

	virtual bool init(int server_id, int server_type, char * entry_file_name);

	virtual bool CheckPluto(Pluto &u);
	virtual int HandlePluto(Pluto &u) = 0;
	virtual void HandleDisconnect(Mailbox *pmb) = 0;
	virtual void HandleConnectToSuccess(Mailbox *pmb) = 0;
};

#endif
