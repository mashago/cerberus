
#include <set>
#include <string>

#include "common.h"
#include "logger.h"
#include "net_service.h"
#include "luaworld.h"
#include "tinyxml2.h"

bool test_load_config()
{
	const char *conf_file = "../conf/server_conf_demo.xml";

	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		LOG_ERROR("load conf error %s", conf_file);
		return false;
	}

	tinyxml2::XMLElement *root = doc.FirstChildElement();
	int server_id = root->IntAttribute("id");
	int server_type = root->IntAttribute("type");
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	const char *entry_file = (char*)root->Attribute("file");
	LOG_DEBUG("server_id=%d server_type=%d ip=%s port=%d entry_file=%s"
	, server_id, server_type, ip, port, entry_file);

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

	return true;
}

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

	test_load_config();

	return 0;
}
