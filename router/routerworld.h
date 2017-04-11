
#ifndef __ROUTERWORLD_H__
#define __ROUTERWORLD_H__

#include "world.h"

class RouterWorld : public World
{
public:
	RouterWorld();
	virtual ~RouterWorld();

private:
	virtual int FromRpcCall(Pluto &u) override;
};

#endif
