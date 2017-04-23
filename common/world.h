
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
	virtual void HandleDisconnect(MailBox *pmb) = 0;
	virtual void HandleConnectToSuccess(MailBox *pmb) = 0;
};

#endif
