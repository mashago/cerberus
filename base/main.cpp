
#include "net_service.h"

int main(int argc, char ** argv)
{
	printf("hello %s\n", argv[0]);

	NetService *ns = new NetService();
	ns->Service("0.0.0.0", 7711);

	return 0;
}
