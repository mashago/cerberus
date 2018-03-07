
#include <set>
#include <string>

#include "common.h"
#include "logger.h"
#include "net_service.h"
#include "luaclient.h"
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
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		printf("load conf error %s\n", conf_file);
		return 0;
	}

	tinyxml2::XMLElement *root = doc.FirstChildElement();
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	const char *entry_path = (char*)root->Attribute("path");
	printf("ip=%s port=%d entry_path=%s\n", ip, port, entry_path);

	if (!strcmp(entry_path, ""))
	{
		printf("entry_path error\n");
		return 0;
	}
	//

	LOG_INIT(entry_path, true);

	// init msg pipe
	EventPipe *net2worldPipe = new EventPipe();
	EventPipe *world2newPipe = new EventPipe(false);

	World *world = new LuaClient();
	world->SetEventPipe(net2worldPipe, world2newPipe);
	world->Init(0, 0, conf_file, entry_path);
	world->Dispatch();

	NetService *net = new NetService();
	net->Init("", 0, false, net2worldPipe, world2newPipe);
	net->Dispatch();

	return 0;
}