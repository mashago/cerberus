
#include "net_server.h"

int main(int argc, char ** argv)
{
	printf("hello %s\n", argv[0]);

	NetServer *ns = new NetServer();
	ns->Service("0.0.0.0", 7711);

	return 0;
}
