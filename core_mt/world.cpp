
#include "logger.h"
#include "world.h"
#include "mailbox.h"
#include "timermgr.h"

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

void World::HandleStdin(const char *buffer)
{
	// default do nothing
}

void World::HandleEvent(const EventNode &node)
{
	switch (node.type)
	{
		case EVENT_TYPE::EVENT_TYPE_NEW_CONNECTION:
		{
			const EventNodeNewConnection &n = (EventNodeNewConnection&)node;
			HandleNewConnection(n.mailboxId, n.connType);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_CONNNECT_TO_SUCCESS:
		{
			const EventNodeConnectToSuccess &n = (EventNodeConnectToSuccess&)node;
			HandleConnectToSuccess(n.mailboxId);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_DISCONNECT:
		{
			const EventNodeDissconnect &n = (EventNodeDissconnect&)node;
			HandleDisconnect(n.mailboxId);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_TIMER:
		{
			// const EventNodeTimer &n = (EventNodeTimer&)node;
			TimerMgr::OnTimer();
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_MSG:
		{
			const EventNodeMsg &n = (EventNodeMsg&)node;
			HandlePluto(*n.pu);
			delete n.pu;
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_STDIN:
		{
			const EventNodeStdin &n = (EventNodeStdin&)node;
			HandleStdin(n.buffer);
			break;
		}
	}
}

void World::RecvEvent()
{
	const std::list<EventNode *> &eventList = m_net2worldPipe->Pop();
	for (auto iter = eventList.begin(); iter != eventList.end(); ++iter)
	{
		HandleEvent(**iter);
		delete *iter;
	}
}

void World::SendEvent(EventNode *node)
{
	m_world2netPipe->Push(node);
}
