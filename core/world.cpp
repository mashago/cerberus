
#include "logger.h"
#include "world.h"
#include "mailbox.h"

World::World() : m_net(nullptr)
{
}

World::~World()
{
}

bool World::Init(int server_id, int server_type, const char *conf_file, const char *entry_file)
{
	return true;
}

bool World::CheckPluto(Pluto &u)
{
	Mailbox *pmb = u.GetMailbox();
	if (pmb == nullptr)
	{
		// may from local rpc
		LOG_INFO("mailbox null mailboxId=%ld", pmb->GetMailboxId());
		return true;
	}

	if (pmb->IsDelete())
	{
		// mailbox will be delete, client is already disconnect, no need to handle this pluto
		LOG_INFO("mailbox delete mailboxId=%ld", pmb->GetMailboxId());
		return false;
	}

	return true;
}

void World::HandleNewConnection(Mailbox *pmb)
{
	// default do nothing
}
