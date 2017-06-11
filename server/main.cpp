
#include "logger.h"
#include "net_service.h"
#include "routerworld.h"
#include "luaworld.h"

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

	// Server [type] [port] [config_file]
	if (argc < 3) 
	{
		LOG_ERROR("arg error");
		return 0;
	}

	const char *server_type = argv[1];
	int port = atoi(argv[2]);
	
	NetService *net = new NetService();
	net->Init(NetService::WITH_LISTENER, "0.0.0.0", port);

	World *world = nullptr;
	if (!strcmp(server_type, "router")) 
	{
		world = new RouterWorld();
	}
	else
	{
		world = LuaWorld::Instance();
	}

	if (nullptr == world)
	{
		LOG_ERROR("server type error");
		return 0;
	}

	net->SetWorld(world);
	world->SetNetService(net);
	world->Init(1, 1, "game_svr/main"); // TODO read from config

	net->Service();

	return 0;
}
