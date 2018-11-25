
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
	struct lua_State *L = luaL_newstate();
	luaL_openlibs(L);
	if (luaL_dofile(L, conf_file))
	{
		printf("load conf error %s!!!!\n", conf_file);
		return 0;
	}

	printf("top=%d\n", lua_gettop(L));

	lua_getfield(L, -1, "id");
	if (!lua_isinteger(L, -1))
	{
		printf("load conf error %s!!!!\n", conf_file);
		return 0;
	}
	int server_id = lua_tointeger(L, -1);
	lua_pop(L, 1);
	printf("server_id=%d\n", server_id);

	int auto_shutdown = 0;
	lua_getfield(L, -1, "auto_shutdown");
	if (!lua_isnil(L, -1))
	{
		auto_shutdown = 1;
	}
	lua_pop(L, 1);
	printf("auto_shutdown=%d\n", auto_shutdown);

	lua_getfield(L, -1, "path");
	if (!lua_isstring(L, -1))
	{
		printf("load conf error %s!!!!\n", conf_file);
		return 0;
	}
	std::string entry_path(lua_tostring(L, -1));
	lua_pop(L, 1);
	printf("entry_path=%s\n", entry_path.c_str());
	if (entry_path == "")
	{
		printf("entry_path error\n");
		return 0;
	}
	lua_close(L);
	//

	char log_file_name[100];
	sprintf(log_file_name, "%s%d", entry_path.c_str(), server_id);
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
