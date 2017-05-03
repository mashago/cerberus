
#include "logger.h"
#include "net_service.h"
#include "routerworld.h"
#include "luaworld.h"

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

	NetService *net = new NetService();
	net->Init(NetService::WITH_LISTENER, "0.0.0.0", 7711);

	World *world = nullptr;
	if (!strcmp(argv[1], "router")) 
	{
		world = new RouterWorld();
	}
	else
	{
		world = new LuaWorld();
	}
	net->SetWorld(world);
	world->SetNetService(net);
	world->Init(1, 1, "script/main.lua");

	net->Service();

	return 0;
}
