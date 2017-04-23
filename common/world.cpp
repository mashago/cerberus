
#include "logger.h"
#include "world.h"
#include "mailbox.h"

World::World()
{
}

World::~World()
{
}

bool World::CheckPluto(Pluto &u)
{
	MailBox *pmb = u.m_pmb;
	if (pmb == nullptr)
	{
		// may from local rpc
		return true;
	}

	if (pmb->IsDelete())
	{
		// mailbox will be delete, client is already disconnect, no need to handle this pluto
		LOG_INFO("mailbox delete fd=%d", pmb->m_fd);
		return false;
	}

	return true;
}
