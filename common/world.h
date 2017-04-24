
#ifndef __WORLD_H__
#define __WORLD_H__

#include "pluto.h"

class World
{
public:
	World();
	virtual ~World();

	virtual int HandlePluto(Pluto &u) = 0;
	virtual bool CheckPluto(Pluto &u);
	virtual void HandleDisconnect(Mailbox *pmb) = 0;
	virtual void HandleConnectToSuccess(Mailbox *pmb) = 0;
};

#endif
