
extern "C"
{
#ifndef WIN32
#include <unistd.h>
#endif
#include <stdlib.h>
#include <fcntl.h>
#include <signal.h>
}

#include <set>
#include <string>

#include "common.h"
#include "logger.h"
#include "net_service.h"
#include "luaworld.h"
#include "tinyxml2.h"
#include "event_pipe.h"

#ifndef WIN32
// copy from redis
void daemonize(void)
{
	int fd;

	if (fork() != 0) exit(0); /* parent exits */
	setsid(); /* create a new session */

	/* Every output goes to /dev/null. If Redis is daemonized but 
	 * the 'logfile' is set to 'stdout' in the configuration file 
	 * it will not log at all. */
	if ((fd = open("/dev/null", O_RDWR, 0)) != -1) {  
		dup2(fd, STDIN_FILENO);  
		dup2(fd, STDOUT_FILENO);  
		dup2(fd, STDERR_FILENO);  
		if (fd > STDERR_FILENO) close(fd);  
	}  
} 
#endif

int main(int argc, char ** argv)
{
	printf("%s\n", argv[0]);
	

	// Server [config_file]
	if (argc < 2) 
	{
		printf("arg error\n");
		return 0;
	}

#ifdef WIN32
	WSADATA wsa_data;
	WSAStartup(0x0201, &wsa_data);
	const char *conf_file = argv[1];
#else
	signal(SIGHUP,  SIG_IGN );
	signal(SIGCHLD,  SIG_IGN );
	bool is_daemon = false;
	const char *conf_file = "";

	int c;
	while ((c = getopt(argc, argv, "dc:")) != -1)
	{
		switch (c)
		{
			case 'd':
				is_daemon = true;
				break;
			case 'c':
				conf_file = optarg;
				break;
		}
	}

	if (is_daemon)
	{
		daemonize();
	}
#endif

	// load config
	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		printf("load conf error %s!!!!\n", conf_file);
		return 0;
	}
	tinyxml2::XMLElement *root = doc.FirstChildElement();
	int server_id = root->IntAttribute("id");
	int server_type = root->IntAttribute("type");
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	int max_conn = root->IntAttribute("max_conn");
	const char *entry_path = (char*)root->Attribute("path");
	int auto_shutdown = root->IntAttribute("auto_shutdown");
	int no_broadcast = root->IntAttribute("no_broadcast");


	printf("server_id=%d server_type=%d ip=%s port=%d max_conn=%d entry_path=%s auto_shutdown=%d no_broadcast=%d\n"
	, server_id, server_type, ip, port, max_conn, entry_path, auto_shutdown, no_broadcast);
	if (!strcmp(entry_path, ""))
	{
		printf("entry_path error\n");
		return 0;
	}
	//

	char log_file_name[100];
	sprintf(log_file_name, "%s%d", entry_path, server_id);
	LOG_INIT(log_file_name, true);

	// init msg pipe
	EventPipe *net2worldPipe = new EventPipe();
	EventPipe *world2newPipe = new EventPipe(false);

	World *world = new LuaWorld();
	world->SetEventPipe(net2worldPipe, world2newPipe);
	world->Init(server_id, server_type, conf_file, entry_path);

	if (auto_shutdown)
	{
		printf("******* %s auto shutdown *******\n", conf_file);
		getchar();
		return 0;
	}
	world->Dispatch();

	NetService *net = new NetService();
	if (net->Init(ip, port, max_conn, is_daemon, net2worldPipe, world2newPipe) != 0)
	{
		printf("net service init error\n");
		return 0;
	}
	net->Dispatch();

	return 0;
}
