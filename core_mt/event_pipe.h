
#pragma once

#include <list>
#include <utility>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <memory>

#include "common.h"

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
	}
	int64_t mailboxId;
	int32_t connType;
};

struct EventNodeConnectToSuccess : public EventNode
{
	EventNodeConnectToSuccess() : EventNode(EVENT_TYPE::EVENT_TYPE_CONNECT_TO_SUCCESS)
	{
	}
	int64_t mailboxId;
};

struct EventNodeDisconnect : public EventNode
{
	EventNodeDisconnect() : EventNode(EVENT_TYPE::EVENT_TYPE_DISCONNECT)
	{
	}
	int64_t mailboxId;
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
	Pluto *pu;
};

struct EventNodeStdin : public EventNode
{
	EventNodeStdin() : EventNode(EVENT_TYPE::EVENT_TYPE_STDIN)
	{
	}
	~EventNodeStdin()
	{
		delete buffer;
	}
	char *buffer = NULL;
};

struct EventNodeConnectToReq : public EventNode
{
	EventNodeConnectToReq() : EventNode(EVENT_TYPE::EVENT_TYPE_CONNECT_TO_REQ)
	{
	}
	char ip[50];	
	unsigned int port;
	int64_t ext;
};

struct EventNodeConnectToRet : public EventNode
{
	EventNodeConnectToRet() : EventNode(EVENT_TYPE::EVENT_TYPE_CONNECT_TO_RET)
	{
	}
	int64_t ext;
	int64_t mailboxId;
};

struct EventNodeHttpReq : public EventNode
{
	EventNodeHttpReq() : EventNode(EVENT_TYPE::EVENT_TYPE_HTTP_REQ)
	{
	}
	~EventNodeHttpReq()
	{
		delete url;
		delete data;
	}
	char *url = NULL;
	int64_t session_id;
	int32_t request_type; // 1 for get, 2 for post
	char *data = NULL;
	int32_t data_len;
};

struct EventNodeHttpRsp : public EventNode
{
	EventNodeHttpRsp() : EventNode(EVENT_TYPE::EVENT_TYPE_HTTP_RSP)
	{
	}
	int64_t session_id;
};

//////////////////////////////////////////////

template <typename T>
class SwitchList
{
public:
	typedef std::list<T> NodeList;
	
	SwitchList() {}
	~SwitchList() {}

	template <typename TT>
	void Push(TT &&task)
	{
		m_pInList->push_back(std::forward<TT>(task));
	}

	void Switch()
	{
		std::swap(m_pInList, m_pOutList);
	}

	void CleanOut()
	{
		m_pOutList->clear();
	}

	int GetInSize()
	{
		return m_pInList->size();
	}

	int GetOutSize()
	{
		return m_pOutList->size();
	}

	bool IsInEmpty()
	{
		return m_pInList->empty();
	}

	bool IsOutEmpty()
	{
		return m_pOutList->empty();
	}

	const NodeList & InList()
	{
		return *m_pInList;
	}

	const NodeList & OutList()
	{
		return *m_pOutList;
	}

private:
	NodeList m_list1;
	NodeList m_list2;
	NodeList *m_pInList = &m_list1;
	NodeList *m_pOutList = &m_list2;
};

class EventPipe
{
public:
	EventPipe(bool isBlockWait = true);
	~EventPipe();
	EventPipe(const EventNode &) = delete;
	EventPipe & operator=(const EventPipe &) = delete;

	void Push(EventNode *node);
	const std::list<EventNode *> & Pop();

private:
	std::mutex m_mtx;
	std::condition_variable m_cv;
	bool m_isBlockWait;
	SwitchList<EventNode *> m_eventList;

	void Switch();
};
