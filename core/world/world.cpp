
#include "logger.h"
#include "world.h"
#include "timermgr.h"
#include "event_pipe.h"
#include "pluto.h"

World::World() : m_isRunning(false), m_inputPipe(nullptr), m_outputPipe(nullptr), m_timerMgr(nullptr)
{
	m_timerMgr = new TimerMgr();
}

World::~World()
{
	m_isRunning = false;
	m_thread.join();
	delete m_timerMgr;
}

bool World::Init(int server_id, int server_type, const char *conf_file, const char *entry_path, EventPipe *inputPipe, EventPipe *outputPipe)
{
	SetEventPipe(inputPipe, outputPipe);
	return CoreInit(server_id, server_type, conf_file, entry_path);
}

void World::SetEventPipe(EventPipe *inputPipe, EventPipe *outputPipe)
{
	m_inputPipe = inputPipe;
	m_outputPipe = outputPipe;
}

bool World::CoreInit(int server_id, int server_type, const char *conf_file, const char *entry_path)
{
	return true;
}

void World::Dispatch()
{
	if (m_isRunning)
	{
		return;
	}
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
			HandleNewConnection(real_node.mailboxId, real_node.ip, real_node.port);
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
	const std::list<EventNode *> &eventList = m_inputPipe->Pop();
	for (auto iter = eventList.begin(); iter != eventList.end(); ++iter)
	{
		HandleEvent(**iter);
		delete *iter; // net new, world delete
	}
}

void World::SendEvent(EventNode *node)
{
	m_outputPipe->Push(node);
}
