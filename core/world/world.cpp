
#include "logger.h"
#include "world.h"
#include "pluto.h"
#include "mailbox.h"
#include "timermgr.h"
#include "event_pipe.h"
#include "timermgr.h"

World::World() : m_isRunning(false), m_timerMgr(nullptr), m_net2worldPipe(nullptr), m_world2netPipe(nullptr)
{
	m_timerMgr = new TimerMgr();
}

World::~World()
{
	m_isRunning = false;
	m_thread.join();
	delete m_timerMgr;
}

void World::SetEventPipe(EventPipe *net2worldPipe, EventPipe *world2netPipe)
{
	m_net2worldPipe = net2worldPipe;
	m_world2netPipe = world2netPipe;
}

bool World::Init(int server_id, int server_type, const char *conf_file, const char *entry_file)
{
	return true;
}

void World::Dispatch()
{
	auto world_run = [](World *world)
	{
		while (world->m_isRunning)
		{
			world->RecvEvent();
		}
	};
	m_isRunning = true;
	m_thread = std::thread(world_run, this);
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
			const EventNodeNewConnection &real_node = (EventNodeNewConnection&)node;
			HandleNewConnection(real_node.mailboxId, real_node.connType);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_CONNECT_TO_SUCCESS:
		{
			const EventNodeConnectToSuccess &real_node = (EventNodeConnectToSuccess&)node;
			HandleConnectToSuccess(real_node.mailboxId);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_DISCONNECT:
		{
			const EventNodeDisconnect &real_node = (EventNodeDisconnect&)node;
			HandleDisconnect(real_node.mailboxId);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_TIMER:
		{
			// const EventNodeTimer &real_node = (EventNodeTimer&)node;
			m_timerMgr->OnTimer();
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_MSG:
		{
			const EventNodeMsg &real_node = (EventNodeMsg&)node;
			HandleMsg(*real_node.pu);
			delete real_node.pu; // net new, world delete
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_STDIN:
		{
			const EventNodeStdin &real_node = (EventNodeStdin&)node;
			HandleStdin(real_node.buffer);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_CONNECT_TO_RET:
		{
			const EventNodeConnectToRet &real_node = (EventNodeConnectToRet&)node;
			HandleConnectToRet(real_node.ext, real_node.mailboxId);
			break;
		}
		case EVENT_TYPE::EVENT_TYPE_HTTP_RSP:
		{
			const EventNodeHttpRsp &real_node = (EventNodeHttpRsp&)node;
			HandleHttpResponse(real_node.session_id, real_node.response_code, real_node.content, real_node.content_len);
			break;
		}
		default:
			LOG_ERROR("cannot handle this node %d", node.type);
			break;
	}
}

void World::RecvEvent()
{
	const std::list<EventNode *> &eventList = m_net2worldPipe->Pop();
	for (auto iter = eventList.begin(); iter != eventList.end(); ++iter)
	{
		HandleEvent(**iter);
		delete *iter; // net new, world delete
	}
}

void World::SendEvent(EventNode *node)
{
	m_world2netPipe->Push(node);
}
