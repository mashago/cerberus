
#include "logger.h"
#include "net_service.h"
#include "routerworld.h"

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

	World *w = new RouterWorld();
	NetService *ns = new NetService();
	ns->SetWorld(w);
	ns->Service("0.0.0.0", 7711);

	return 0;
}
