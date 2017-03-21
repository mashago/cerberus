
#include "logger.h"
#include "net_service.h"
#include "baseworld.h"

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

	World *w = new BaseWorld();
	NetService *ns = new NetService();
	ns->SetWorld(w);
	ns->Service("0.0.0.0", 7711);

	return 0;
}
