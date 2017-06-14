
#include "common.h"
#include "logger.h"
#include "net_service.h"
#include "routerworld.h"
#include "luaworld.h"
#include "tinyxml2.h"

bool test_load_config()
{
	const char *conf_file = "../conf/server_conf_test.xml";
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		LOG_ERROR("load conf error %s", conf_file);
		return false;
	}

	tinyxml2::XMLElement* root = doc.FirstChildElement();
	int server_id = root->IntAttribute("id");
	int server_type = root->IntAttribute("type");
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	const char *entry_file = (char*)root->Attribute("file");
	LOG_DEBUG("server server_id=%d server_type=%d ip=%s port=%d entry_file=%s"
	, server_id, server_type, ip, port, entry_file);

	if (tinyxml2::XMLElement* connect_to_ele = root->FirstChildElement("connect_to"))
	{
		tinyxml2::XMLElement* address_ele = connect_to_ele->FirstChildElement("address");
		while (address_ele)
		{
			char* ip = (char*)address_ele->Attribute("ip");
			int port = address_ele->IntAttribute("port");
			if (ip == nullptr || port <= 0)
			{
				break;
			}
			LOG_DEBUG("address ip=%s port=%d", ip, port);

			address_ele = address_ele->NextSiblingElement();
		}
	}

	return true;
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

	// test_load_config();

	// load config
	const char *conf_file = argv[1];
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		LOG_ERROR("load conf error %s", conf_file);
		return 0;
	}

	tinyxml2::XMLElement* root = doc.FirstChildElement();
	int server_id = root->IntAttribute("id");
	int server_type = root->IntAttribute("type");
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	const char *entry_file = (char*)root->Attribute("file");
	LOG_DEBUG("server_id=%d server_type=%d ip=%s port=%d entry_file=%s"
	, server_id, server_type, ip, port, entry_file);
	//

	NetService *net = new NetService();
	net->Init(ip, port);

	World *world = nullptr;
	if (server_type == E_SERVER_TYPE::SERVER_TYPE_ROUTER)
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
	world->Init(server_id, server_type, conf_file, entry_file);

	net->Service();

	return 0;
}
