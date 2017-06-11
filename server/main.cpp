
#include "logger.h"
#include "net_service.h"
#include "routerworld.h"
#include "luaworld.h"
#include "tinyxml2.h"

void init_config()
{
	const char *file_name = "../conf/server_conf7712.xml";
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(file_name) != tinyxml2::XMLError::XML_SUCCESS)
	{
		LOG_ERROR("load conf error %s", file_name);
		return;
	}

	tinyxml2::XMLElement* root = doc.FirstChildElement();
	{
		if (tinyxml2::XMLElement* connectsvrs_ele = root->FirstChildElement("connect_to")){
			tinyxml2::XMLElement* svr_ele = connectsvrs_ele->FirstChildElement("svr");
			while (svr_ele){
				int svr_id = svr_ele->IntAttribute("id");
				int svr_type = svr_ele->IntAttribute("type");
				char* ip = (char*)svr_ele->Attribute("ip");
				int port = svr_ele->IntAttribute("port");

				if (svr_id <= 0 || svr_type <= 0 || ip == nullptr || port <= 0){
					// std::cout << "Init from file " << file_name << " connect attribute error !!!" << std::endl;
					return ;
				}

				svr_ele = svr_ele->NextSiblingElement();
			}
		}
	}
}

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
