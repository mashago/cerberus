
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
	LOG_DEBUG("%s", argv[0]);

#ifdef WIN32
	WSADATA wsa_data;
	WSAStartup(0x0201, &wsa_data);
#endif

	// LuaClient [config_file]
	if (argc < 2) 
	{
		LOG_ERROR("arg error");
		return 0;
	}
	const char *conf_file = argv[1];
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		LOG_ERROR("load conf error %s", conf_file);
		return 0;
	}

	tinyxml2::XMLElement *root = doc.FirstChildElement();
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	const char *entry_file = (char*)root->Attribute("file");
	LOG_DEBUG("ip=%s port=%d entry_file=%s", ip, port, entry_file);
	//

	// init msg pipe
	EventPipe *net2worldPipe = new EventPipe();
	EventPipe *world2newPipe = new EventPipe(false);

	World *world = new LuaClient();
	world->SetEventPipe(net2worldPipe, world2newPipe);
	world->Init(0, 0, conf_file, entry_file);
	world->Run();

	NetService *net = new NetService();
	std::set<std::string> trustIpSet;
	net->Init("", 0, trustIpSet, net2worldPipe, world2newPipe);
	net->Service();

	return 0;
}
