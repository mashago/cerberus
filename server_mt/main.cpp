
#include <set>
#include <string>
#include <thread>

#include "common.h"
#include "logger.h"
#include "net_service.h"
#include "luaworld.h"
#include "tinyxml2.h"
#include "event_pipe.h"

void world_run(World *world)
{
	while (true)
	{
		world->RecvEvent();
	}
}

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

	// Server [config_file]
	if (argc < 2) 
	{
		LOG_ERROR("arg error");
		return 0;
	}

	// load config
	const char *conf_file = argv[1];
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		LOG_ERROR("load conf error %s", conf_file);
		return 0;
	}

	tinyxml2::XMLElement *root = doc.FirstChildElement();
	int server_id = root->IntAttribute("id");
	int server_type = root->IntAttribute("type");
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	const char *entry_file = (char*)root->Attribute("file");
	int auto_shutdown = root->IntAttribute("auto_shutdown");
	int no_broadcast = root->IntAttribute("no_broadcast");

	LOG_DEBUG("server_id=%d server_type=%d ip=%s port=%d entry_file=%s auto_shutdown=%d no_broadcast=%d"
	, server_id, server_type, ip, port, entry_file, auto_shutdown, no_broadcast);

	std::set<std::string> trustIpSet;
	tinyxml2::XMLElement *trust_ip = root->FirstChildElement("trust_ip");
	if (trust_ip)
	{
		tinyxml2::XMLElement *addr = trust_ip->FirstChildElement("address");
		while (addr)
		{
			const char *ip = (char *)addr->Attribute("ip");
			LOG_DEBUG("trust ip=%s", ip);
			trustIpSet.insert(ip);
			addr = addr->NextSiblingElement();
		}
	}
	//

	// init msg pipe
	EventPipe *net2worldPipe = new EventPipe();
	EventPipe *world2newPipe = new EventPipe();

	NetService *net = new NetService();
	net->Init(ip, port, trustIpSet, net2worldPipe, world2newPipe);

	World *world = nullptr;
	{
		world = LuaWorld::Instance();
	}

	if (nullptr == world)
	{
		LOG_ERROR("server type error");
		return 0;
	}

	world->SetEventPipe(net2worldPipe, world2newPipe);

	world->Init(server_id, server_type, conf_file, entry_file);

	if (auto_shutdown)
	{
		printf("******* %s auto shutdown *******\n", conf_file);
		return 0;
	}

	std::thread world_thread;
	world_thread = std::thread([world](){ world_run(world); });

	net->Service();

	return 0;
}
