
#pragma once

#include <list>
#include <utility>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <memory>

#include "util.h"

class Pluto;

enum EVENT_TYPE
{
	EVENT_TYPE_NEW_CONNECTION 			= 1, // n2w
	EVENT_TYPE_CONNECT_TO_SUCCESS 		= 2, // n2w
	EVENT_TYPE_DISCONNECT 				= 3, // n2w, w2n
	EVENT_TYPE_TIMER 					= 4, // n2w
	EVENT_TYPE_MSG 						= 5, // n2w, w2n
	EVENT_TYPE_STDIN 					= 6, // n2w
	EVENT_TYPE_CONNECT_TO_REQ 			= 7, // w2n
	EVENT_TYPE_CONNECT_TO_RET 			= 8, // n2w
	EVENT_TYPE_HTTP_REQ 				= 9, // w2n
	EVENT_TYPE_HTTP_RSP 				= 10, // n2w
	EVENT_TYPE_LISTEN_REQ 				= 11, // w2n
	EVENT_TYPE_LISTEN_RET 				= 12, // n2w
	EVENT_TYPE_SUBTHREAD_JOB_REQ 		= 13, // w2t
	EVENT_TYPE_SUBTHREAD_JOB_RET 		= 14, // w2t
	EVENT_TYPE_SYNC_CONNECT_TO_REQ 		= 15, // w2n
};

struct EventNode
{
	int type;
protected:
	EventNode(int t) : type(t) {}
};

struct EventNodeNewConnection : public EventNode
{
	EventNodeNewConnection() : EventNode(EVENT_TYPE::EVENT_TYPE_NEW_CONNECTION)
	{
		memset(ip, 0, sizeof(ip));
	}
	int64_t mailboxId = -1;
	char ip[50];
	int port = 0;
	int64_t listenId = -1;
};

struct EventNodeConnectToSuccess : public EventNode
{
	EventNodeConnectToSuccess() : EventNode(EVENT_TYPE::EVENT_TYPE_CONNECT_TO_SUCCESS)
	{
	}
	int64_t mailboxId = -1;
};

struct EventNodeDisconnect : public EventNode
{
	EventNodeDisconnect() : EventNode(EVENT_TYPE::EVENT_TYPE_DISCONNECT)
	{
	}
	int64_t mailboxId = -1;
};

struct EventNodeTimer : public EventNode
{
	EventNodeTimer() : EventNode(EVENT_TYPE::EVENT_TYPE_TIMER)
	{
	}
};

struct EventNodeMsg : public EventNode
{
	EventNodeMsg() : EventNode(EVENT_TYPE::EVENT_TYPE_MSG)
	{
	}
	// note:
	// will not do delete pu in ~(), because pu may send by net
	Pluto *pu = nullptr;
};

struct EventNodeStdin : public EventNode
{
	EventNodeStdin() : EventNode(EVENT_TYPE::EVENT_TYPE_STDIN)
	{
	}
	~EventNodeStdin()
	{
		delete [] buffer;
	}
	char *buffer = NULL;
};

struct EventNodeConnectToReq : public EventNode
{
	EventNodeConnectToReq() : EventNode(EVENT_TYPE::EVENT_TYPE_CONNECT_TO_REQ)
	{
		memset(ip, 0, sizeof(ip));
	}
	char ip[50];
	unsigned int port = 0;
	int64_t ext = 0;
};

struct EventNodeConnectToRet : public EventNode
{
	EventNodeConnectToRet() : EventNode(EVENT_TYPE::EVENT_TYPE_CONNECT_TO_RET)
	{
	}
	int64_t ext = 0;
	int64_t mailboxId = -1;
};

struct EventNodeSyncConnectToReq : public EventNode
{
	EventNodeSyncConnectToReq() : EventNode(EVENT_TYPE::EVENT_TYPE_SYNC_CONNECT_TO_REQ)
	{
		memset(ip, 0, sizeof(ip));
	}
	int64_t session_id = 0;
	char ip[50];
	unsigned int port = 0;
};

struct EventNodeHttpReq : public EventNode
{
	EventNodeHttpReq() : EventNode(EVENT_TYPE::EVENT_TYPE_HTTP_REQ)
	{
	}
	~EventNodeHttpReq()
	{
		delete [] url;
		delete [] post_data;
	}
	char *url = NULL;
	int64_t session_id = 0;
	int32_t request_type = 0; // 1 for get, 2 for post
	char *post_data = NULL;
	int32_t post_data_len = 0;
};

struct EventNodeHttpRsp : public EventNode
{
	EventNodeHttpRsp() : EventNode(EVENT_TYPE::EVENT_TYPE_HTTP_RSP)
	{
		delete [] content;
	}
	int64_t session_id = 0;
	int response_code = 0;
	char *content = NULL;
	int32_t content_len = 0;

};

struct EventNodeListenReq : public EventNode
{
	EventNodeListenReq() : EventNode(EVENT_TYPE::EVENT_TYPE_LISTEN_REQ)
	{
		memset(ip, 0, sizeof(ip));
	}
	char ip[50];
	unsigned int port = 0;
	int64_t session_id = 0;
};

struct EventNodeListenRet : public EventNode
{
	EventNodeListenRet() : EventNode(EVENT_TYPE::EVENT_TYPE_LISTEN_RET)
	{
	}
	int64_t listenId = -1;
	int64_t session_id = 0;
};

struct EventNodeSubThreadJobReq : public EventNode
{
	EventNodeSubThreadJobReq() : EventNode(EVENT_TYPE::EVENT_TYPE_SUBTHREAD_JOB_REQ)
	{
	}
	~EventNodeSubThreadJobReq()
	{
		delete [] func_name;
		delete [] params;
	}
	int64_t session_id;
	char *func_name = NULL;
	char *params = NULL;
	int len = 0;
};

//////////////////////////////////////////////

class EventPipe
{
public:
	EventPipe(bool isBlockPop = true);
	~EventPipe();
	EventPipe(const EventPipe &) = delete;
	EventPipe & operator=(const EventPipe &) = delete;

	void Push(EventNode *node);
	const std::list<EventNode *> & Pop();

private:
	std::mutex m_mtx;
	std::condition_variable m_cv;
	const bool m_isBlockWait;
	SwitchList<EventNode *> m_eventList;

	void Switch();
};
