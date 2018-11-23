
#ifdef WIN32
#else
#endif

#include <set>
#include <string>

#include "common.h"
#include "logger.h"
#include "net_service.h"
#include "luaworld.h"
#include "tinyxml2.h"
#include "event_pipe.h"

int main(int argc, char ** argv)
{
	printf("%s\n", argv[0]);

#ifdef WIN32
	WSADATA wsa_data;
	WSAStartup(0x0201, &wsa_data);
#endif

	// LuaClient [config_file]
	if (argc < 2) 
	{
		printf("arg error\n");
		return 0;
	}
	const char *conf_file = argv[1];

	// load config
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		printf("load conf error %s\n", conf_file);
		return 0;
	}

	tinyxml2::XMLElement *root = doc.FirstChildElement();
	const char *entry_path = (char*)root->Attribute("path");

	printf("entry_path=%s\n", entry_path);
	if (!strcmp(entry_path, ""))
	{
		printf("entry_path error\n");
		return 0;
	}
	//

	LOG_INIT(entry_path, true);

	// init msg pipe
	EventPipe *net2worldPipe = new EventPipe();
	EventPipe *world2netPipe = new EventPipe(false);

	LuaWorld *world = new LuaWorld();
	if (!world->Init(conf_file, net2worldPipe, world2netPipe))
	{
		printf("world init error\n");
		getchar();
		return 0;
	}
	world->Dispatch();

	NetService *net = new NetService();
	if (!net->Init(false, world2netPipe, net2worldPipe))
	{
		printf("net service init error\n");
		getchar();
		return 0;
	}
	net->Dispatch();

	return 0;
}
