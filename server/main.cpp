
#include <set>
#include <string>

#include "common.h"
#include "logger.h"
#include "net_service.h"
#include "luaworld.h"
#include "tinyxml2.h"
#include "event_pipe.h"

static const char *SERVER_NAME_ARRAY[] =
{
	"null"
,	"router_svr"
,	"scene_svr"
,	"db_svr"
,	"bridge_svr"
,	"login_svr"
,	"public_svr"
,	"cross_svr"
,	"pay_svr"
,	"chat_svr"
};

int main(int argc, char ** argv)
{
	printf("%s\n", argv[0]);

#ifdef WIN32
	WSADATA wsa_data;
	WSAStartup(0x0201, &wsa_data);
#endif

	// Server [config_file]
	if (argc < 2) 
	{
		printf("arg error\n");
		return 0;
	}

	// load config
	const char *conf_file = argv[1];
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		printf("load conf error %s\n", conf_file);
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


	printf("server_id=%d server_type=%d ip=%s port=%d entry_file=%s auto_shutdown=%d no_broadcast=%d\n"
	, server_id, server_type, ip, port, entry_file, auto_shutdown, no_broadcast);

	std::set<std::string> trustIpSet;
	tinyxml2::XMLElement *trust_ip = root->FirstChildElement("trust_ip");
	if (trust_ip)
	{
		tinyxml2::XMLElement *addr = trust_ip->FirstChildElement("address");
		while (addr)
		{
			const char *ip = (char *)addr->Attribute("ip");
			trustIpSet.insert(ip);
			addr = addr->NextSiblingElement();
		}
	}
	//

	char log_file_name[100];
	sprintf(log_file_name, "%s%d", SERVER_NAME_ARRAY[server_type], server_id);
	LOG_INIT(log_file_name, true);

	// init msg pipe
	EventPipe *net2worldPipe = new EventPipe();
	EventPipe *world2newPipe = new EventPipe(false);

	World *world = new LuaWorld();
	world->SetEventPipe(net2worldPipe, world2newPipe);
	world->Init(server_id, server_type, conf_file, entry_file);

	if (auto_shutdown)
	{
		printf("******* %s auto shutdown *******\n", conf_file);
		return 0;
	}
	world->Run();

	NetService *net = new NetService();
	net->Init(ip, port, trustIpSet, net2worldPipe, world2newPipe);
	net->Service();

	return 0;
}
