
#ifndef __WORLD_H__
#define __WORLD_H__

#include "pluto.h"

class World
{
public:
	World();
	virtual ~World();

	virtual int FromRpcCall(Pluto &u) = 0;
	virtual bool CheckClientRpc(Pluto &u);
};

#endif
