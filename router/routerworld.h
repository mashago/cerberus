
#ifndef __ROUTERWORLD_H__
#define __ROUTERWORLD_H__

#include "world.h"

class RouterWorld : public World
{
public:
	RouterWorld();
	virtual ~RouterWorld();

private:
	virtual int HandlePluto(Pluto &u) override;
	virtual void HandleDisconnect(Mailbox *pmb) override;
	virtual void HandleConnectToSuccess(Mailbox *pmb) override;
};

#endif
