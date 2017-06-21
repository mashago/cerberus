
#include <set>
#include <string>

#include "common.h"
#include "logger.h"
#include "net_service.h"
#include "luaclient.h"
#include "tinyxml2.h"

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

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
	LOG_DEBUG("ip=%s port=%d entry_file=%s"
	, ip, port, entry_file);

	NetService *net = new NetService();
	std::set<std::string> trustIpSet;
	net->Init("", 0, trustIpSet);

	World *world = nullptr;
	{
		world = LuaClient::Instance();
	}

	if (nullptr == world)
	{
		LOG_ERROR("server type error");
		return 0;
	}

	net->SetWorld(world);
	world->SetNetService(net);
	world->Init(0, 0, conf_file, entry_file);

	net->Service();

	return 0;
}
