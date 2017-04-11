
#ifndef __BASEWORLD_H__
#define __BASEWORLD_H__

#include "world.h"

class BaseWorld : public World
{
public:
	BaseWorld();
	virtual ~BaseWorld();

private:
	virtual int FromRpcCall(Pluto &u) override;
};

#endif
