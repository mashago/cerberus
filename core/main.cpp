
extern "C"
{
#ifdef WIN32
#else
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

	bool is_daemon = false;
#ifdef WIN32
	WSADATA wsa_data;
	WSAStartup(0x0201, &wsa_data);
	const char *conf_file = argv[1];
#else
	signal(SIGHUP,  SIG_IGN );
	signal(SIGCHLD,  SIG_IGN );
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
	const char *entry_path = (char*)root->Attribute("path");
	int auto_shutdown = root->IntAttribute("auto_shutdown");

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
	EventPipe *world2netPipe = new EventPipe(false);

	// net dispatch will block, so world dispatch first, order is important
	LuaWorld *world = new LuaWorld();
	if (!world->Init(conf_file, net2worldPipe, world2netPipe))
	{
		printf("world init error\n");
		return 0;
	}

	if (auto_shutdown)
	{
		printf("******* %s auto shutdown *******\n", conf_file);
		getchar();
		return 0;
	}
	world->Dispatch();

	NetService *net = new NetService();
	if (!net->Init(is_daemon, world2netPipe, net2worldPipe))
	{
		printf("net service init error\n");
		return 0;
	}
	net->Dispatch();

	return 0;
}
