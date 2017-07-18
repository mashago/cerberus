
extern "C"
{
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <strings.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <time.h>
#include <errno.h>

#include <event2/event.h>
#include <event2/listener.h>
#include <event2/util.h>
#include <event2/bufferevent.h>
#include <event2/buffer.h>
}
#include <string>

#include "logger.h"
#include "util.h"
#include "net_service.h"
#include "event_pipe.h"
#include "pluto.h"
#include "mailbox.h"

static void listen_cb(struct evconnlistener *listener, evutil_socket_t fd, struct sockaddr *sa, int socklen, void *user_data);
static void read_cb(struct bufferevent *bev, void *user_data);
static void event_cb(struct bufferevent *bev, short event, void *user_data);
static void tick_cb(evutil_socket_t fd, short event, void *user_data);
static void timer_cb(evutil_socket_t fd, short event, void *user_data);
static void stdin_cb(evutil_socket_t fd, short event, void *user_data);


NetService::NetService() : m_mainEvent(nullptr), m_tickEvent(nullptr), m_timerEvent(nullptr), m_evconnlistener(nullptr)
{
}

NetService::~NetService()
{
}


int NetService::Init(const char *addr, unsigned int port, std::set<std::string> &trustIpSet, EventPipe *net2worldPipe, EventPipe *world2netPipe)
{
	m_trustIpSet = trustIpSet;

	// new event_base
	m_mainEvent = event_base_new();
	if (!m_mainEvent)
	{
		LOG_ERROR("event_base_new fail");
		return -1;
	}

	// listen
	if (port > 0 && !Listen(addr, port))
	{
		LOG_ERROR("listen fail");
		return -1;
	}

	// init tick timer
	m_tickEvent = event_new(m_mainEvent, -1, EV_PERSIST, tick_cb, this);
	struct timeval tv;
	tv.tv_sec = 0;
	// tv.tv_sec = 3;
	tv.tv_usec = 50 * 1000;
	if (event_add(m_tickEvent, &tv) != 0)
	{
		LOG_ERROR("add tick timer fail");
		return -1;
	}

	// init timer
	m_timerEvent = event_new(m_mainEvent, -1, EV_PERSIST, timer_cb, this);
	tv.tv_sec = 0;
	tv.tv_usec = 500 * 1000;
	if (event_add(m_timerEvent, &tv) != 0)
	{
		LOG_ERROR("add normal timer fail");
		return -1;
	}

	// init stdin event
	m_stdinEvent = event_new(m_mainEvent, STDIN_FILENO, EV_READ | EV_PERSIST, stdin_cb, this);
	if (event_add(m_stdinEvent, NULL) != 0)
	{
		LOG_ERROR("add stdin event fail");
		return -1;
	}

	m_net2worldPipe = net2worldPipe;
	m_world2netPipe = world2netPipe;

	return 0;
}

int NetService::Service()
{

	event_base_dispatch(m_mainEvent);

	if (m_tickEvent)
	{
		event_del(m_tickEvent);
		event_free(m_tickEvent);
		m_tickEvent = NULL;
	}

	event_base_free(m_mainEvent);

	return 0;
}

int64_t NetService::ConnectTo(const char *addr, unsigned int port)
{
    // 1. init a sin
	// 2. init buffer socket
	// 3. set nonblock
	// 4. connect
	// 5. new mailbox

    // init a sin
    struct sockaddr_in sin;
    memset(&sin, 0, sizeof(sin));
    sin.sin_family = PF_INET;
    sin.sin_addr.s_addr = inet_addr(addr);
    sin.sin_port = htons(port);

	// init buffer socket
	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, -1, BEV_OPT_CLOSE_ON_FREE); // | BEV_OPT_DEFER_CALLBACKS);
	if (!bev)
	{
        LOG_ERROR("bufferevent new fail");
		return -1;
	}
	bufferevent_setcb(bev, read_cb, NULL, event_cb, (void *)this);
	bufferevent_enable(bev, EV_READ); // XXX consider set EV_PERSIST ?

	// non-block connect
	int ret = bufferevent_socket_connect(bev, (struct sockaddr *)&sin, sizeof(sin));
    if (ret < 0)
    {
        LOG_ERROR("bufferevent connect fail ret=%d", ret);
        bufferevent_free(bev);
        return -1;
    }

	evutil_socket_t fd = bufferevent_getfd(bev);
	LOG_DEBUG("fd=%d", fd);
	// set nonblock
	// evutil_make_socket_nonblocking(fd); // already set non-block in bufferevent_socket_connect()

	// new mailbox
	Mailbox *pmb = NewMailbox(fd, E_CONN_TYPE::CONN_TYPE_TRUST);
	if (!pmb)
	{
		LOG_ERROR("mailbox null fd=%d", fd);
		bufferevent_free(bev);
		return -1;
	}
	pmb->SetBEV(bev);

	return pmb->GetMailboxId();
}

bool NetService::Listen(const char *addr, unsigned int port)
{
	// 1. new event_base
	// 2. init listener
	// 3. set nonblock
	// 4. init timer

	// init listener
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_family = PF_INET;
	sin.sin_addr.s_addr = inet_addr(addr);
	sin.sin_port = htons(port);

	m_evconnlistener = evconnlistener_new_bind(m_mainEvent, listen_cb, (void *)this, LEV_OPT_REUSEABLE|LEV_OPT_CLOSE_ON_FREE, -1, (struct sockaddr *)&sin, sizeof(sin));
	if (!m_evconnlistener)
	{
		LOG_ERROR("new bind fail");
		return false;
	}

	// set nonblock
	evutil_socket_t listen_fd = evconnlistener_get_fd(m_evconnlistener);
	evutil_make_socket_nonblocking(listen_fd);

	return true;
}

Mailbox *NetService::GetMailboxByFd(int fd)
{
	auto iter = m_fds.find(fd);
	if (iter == m_fds.end())
	{
		return nullptr;
	}
	return iter->second;
}

Mailbox *NetService::GetMailboxByMailboxId(int64_t mailboxId)
{
	auto iter = m_mailboxs.find(mailboxId);
	if (iter == m_mailboxs.end())
	{
		return nullptr;
	}
	return iter->second;
}

int NetService::HandleNewConnection(evutil_socket_t fd, struct sockaddr *sa, int socklen)
{
	LOG_DEBUG("fd=%d", fd);

	// 1. check connection num
	// 2. check connection is valide
	// 3. set fd non-block
	// 4. accept clinet
	
	struct sockaddr_in *sin = (struct sockaddr_in *)sa;
	const char *clientHost = inet_ntoa(sin->sin_addr);
	uint16_t clientPort = ntohs(sin->sin_port);
	LOG_DEBUG("clientHost=%s clientPort=%d", clientHost, clientPort);

	// check connection num
	// TODO

	// check connection is trust
	E_CONN_TYPE connType = E_CONN_TYPE::CONN_TYPE_UNTRUST;
	std::string ip(clientHost);

	auto iter = m_trustIpSet.find(ip);
	if (iter != m_trustIpSet.end())
	{
		connType = E_CONN_TYPE::CONN_TYPE_TRUST;
	}
	
	// check connection is valide
	// TODO

	// set fd non-block
	evutil_make_socket_nonblocking(fd);

	// accept client
	// init buffer socket
	struct bufferevent *bev = bufferevent_socket_new(m_mainEvent, fd, BEV_OPT_CLOSE_ON_FREE); // | BEV_OPT_DEFER_CALLBACKS);
	if (!bev)
	{
        LOG_ERROR("bufferevent new fail");
		evutil_closesocket(fd);
		return -1;
	}
	bufferevent_setcb(bev, read_cb, NULL, event_cb, (void *)this);
	bufferevent_enable(bev, EV_READ); // XXX consider set EV_PERSIST ?
	
	// new mailbox
	Mailbox *pmb = NewMailbox(fd, connType);
	if (!pmb)
	{
		LOG_ERROR("mailbox null fd=%d", fd);
		bufferevent_free(bev);
		return -1;
	}
	pmb->SetBEV(bev);

	EventNodeNewConnection *node = new EventNodeNewConnection();
	node->mailboxId = pmb->GetMailboxId();
	node->connType = connType;
	SendEvent(node);

	return 0;
}

Mailbox * NetService::NewMailbox(int fd, E_CONN_TYPE connType)
{
	Mailbox *pmb = new Mailbox(connType);
	if (!pmb)
	{
		return nullptr;
	}

	pmb->SetFd(fd);

	auto iter = m_fds.lower_bound(fd);
	if (iter != m_fds.end() && iter->first == fd)
	{
		// still has old mailbox
		Mailbox *oldmb = iter->second;
		if (oldmb != pmb)
		{
			delete oldmb;
			iter->second = pmb;
		}
		LOG_WARN("has old mailbox fd=%d", fd);
	}
	else
	{
		// normal logic, insert new mailbox
		m_fds.insert(iter, std::make_pair(fd, pmb));
	}
	m_mailboxs[pmb->GetMailboxId()] = pmb;

	return pmb;
}

enum READ_MSG_RESULT
{
	READ_MSG_ERROR 		= -1
,	READ_MSG_WAIT 		= 0 
,	READ_MSG_FINISH 	= 1 
};

int NetService::HandleSocketRead(struct bufferevent *bev)
{
	// loop to handle read data
	
	evutil_socket_t fd = bufferevent_getfd(bev);
	LOG_DEBUG("fd=%d", fd);
	int ret = READ_MSG_WAIT;
	do
	{
		ret = HandleSocketReadMessage(bev);
	} 
	while (ret == READ_MSG_FINISH);

	return 0;
}

int NetService::HandleSocketReadMessage(struct bufferevent *bev)
{
	evutil_socket_t fd = bufferevent_getfd(bev);

	Mailbox *pmb = GetMailboxByFd(fd);
	if (pmb == nullptr)
	{
		return READ_MSG_ERROR;
	}

	// 1. get input evbuffer and length
	// 2. check if has pluto in mailbox
	// 3. copy to pluto buffer
	// 4. if read msg finish, add into recv msg list, and clean mailbox pluto

	// get input evbuffer and length
	struct evbuffer *input = bufferevent_get_input(bev);
	const size_t input_len = evbuffer_get_length(input);

	// LOG_DEBUG("input_len=%lu", input_len);
	if (input_len == 0)
	{
		return READ_MSG_WAIT;
	}

	char *buffer = nullptr;
	int nWanted = 0;
	ev_ssize_t nLen = 0;

	Pluto *pu = pmb->GetRecvPluto();
	if (pu == nullptr)
	{
		// no pluto in mailbox

		if (input_len < PLUTO_MSGLEN_HEAD)
		{
			// data less then msg head
			return READ_MSG_WAIT;
		}

		// get msg head len
		char head[PLUTO_MSGLEN_HEAD];
		nLen= evbuffer_copyout(input, head, PLUTO_MSGLEN_HEAD);
		if (nLen < PLUTO_MSGLEN_HEAD)
		{
			return READ_MSG_WAIT;
		}

		// shift input data
		evbuffer_drain(input, nLen);

		// get msglen
		int msgLen = (int)ntohl(*(uint32_t *)head);
		if (msgLen > MSGLEN_MAX)
		{
			LOG_WARN("msg too long fd=%d msgLen=%d", fd, msgLen);
			// TODO should kick this connection?
		}

		// new a pluto
		pu = new Pluto(msgLen); // net new, world delete
		pmb->SetRecvPluto(pu);

		// copy msghead to buffer
		buffer = pu->GetBuffer();
		memcpy(buffer, head, PLUTO_MSGLEN_HEAD);
		buffer += PLUTO_MSGLEN_HEAD;

		pu->SetRecvLen(PLUTO_MSGLEN_HEAD);
		nWanted = msgLen - PLUTO_MSGLEN_HEAD;
	}

	else
	{
		// already has pluto in mailbox
		buffer = pu->GetBuffer() + pu->GetRecvLen();
		nWanted = pu->GetMsgLen() - pu->GetRecvLen();
	}

	// copy remain data to buffer
	nLen = evbuffer_copyout(input, buffer, nWanted);
	if (nLen <= 0)
	{
		// no more data
		return READ_MSG_WAIT;
	}

	evbuffer_drain(input, nLen);
	if (nLen != nWanted)
	{
		// data not recv finish
		// update recv len
		pu->SetRecvLen(pu->GetRecvLen() + nLen);
		return READ_MSG_WAIT;
	}

	// get a full msg
	// add into recv msg list
	pu->SetRecvLen(pu->GetMsgLen());
	// pu->SetMailbox(pmb);
	pu->SetMailboxId(pmb->GetMailboxId());
	AddRecvMsg(pu);

	// clean mailbox pluto
	pmb->SetRecvPluto(nullptr);

	return READ_MSG_FINISH;
}

void NetService::AddRecvMsg(Pluto *pu)
{
	EventNodeMsg *node = new EventNodeMsg();
	node->pu = pu;
	SendEvent(node);
}


int NetService::HandleSocketConnected(evutil_socket_t fd)
{
	Mailbox *pmb = GetMailboxByFd(fd);
	if (pmb == NULL)
	{
		LOG_WARN("mailbox null fd=%d", fd);
		return 0;
	}

	EventNodeConnectToSuccess *node = new EventNodeConnectToSuccess();
	node->mailboxId = pmb->GetMailboxId();
	SendEvent(node);

	return 0;
}

int NetService::HandleSocketClosed(evutil_socket_t fd)
{
	CloseMailbox(fd);
	return 0;
}

int NetService::HandleSocketError(evutil_socket_t fd)
{
	CloseMailbox(fd);
	return 0;
}

void NetService::HandleWorldEvent()
{
	const std::list<EventNode *> &node_list = m_world2netPipe->Pop();
	for (auto iter = node_list.begin(); iter != node_list.end(); iter++)
	{
		const EventNode &node = **iter;
		// LOG_DEBUG("node.type=%d", node.type);
		switch (node.type)
		{
			case EVENT_TYPE::EVENT_TYPE_DISCONNECT:
			{
				const EventNodeDisconnect &real_node = (EventNodeDisconnect&)node;
				// LOG_DEBUG("mailboxId=%ld", real_node.mailboxId);
				CloseMailbox(real_node.mailboxId);
				break;
			}
			case EVENT_TYPE::EVENT_TYPE_MSG:
			{
				// add pluto into mailbox, set not auto delete pluto from node
				const EventNodeMsg &real_node = (EventNodeMsg&)node;
				Pluto *pu = real_node.pu;
				int64_t mailboxId = pu->GetMailboxId();
				// LOG_DEBUG("mailboxId=%ld", mailboxId);
				Mailbox *pmb = GetMailboxByMailboxId(mailboxId);
				if (!pmb)
				{
					LOG_WARN("mail box null %ld", mailboxId);
					delete pu; // world new, net delete
					break;
				}
				pmb->PushPluto(pu);
				break;
			}
			case EVENT_TYPE::EVENT_TYPE_CONNNECT_TO_REQ:
			{
				const EventNodeConnectToReq &real_node = (EventNodeConnectToReq&)node;
				// LOG_DEBUG("ext=%ld", real_node.ext);
				int64_t mailboxId = ConnectTo(real_node.ip, real_node.port);
				EventNodeConnectToRet *ret_node = new EventNodeConnectToRet();
				ret_node->ext = real_node.ext;
				ret_node->mailboxId = mailboxId;
				SendEvent(ret_node);

				break;
			}
			default:
				LOG_ERROR("cannot handle this node %d", node.type);
				break;
		}

		delete *iter; // world new, net delete
	}
}

void NetService::HandleSendPluto()
{
	// loop all mailbox, do send all
	std::list<Mailbox *> ls4del;
	for (auto iter = m_fds.begin(); iter != m_fds.end(); iter++)
	{
		Mailbox *pmb = iter->second;
		int ret = pmb->SendAll();
		if (ret != 0)
		{
			ls4del.push_back(pmb);
		}
	}

	// close error connect
	for (auto iter = ls4del.begin(); iter != ls4del.end(); iter++)
	{
		CloseMailbox(*iter);
	}
}

void NetService::HandleTickEvent()
{
	// 1. handle world event
	// 2. handle send pluto
	// 3. delete mailbox

	// handle world event
	HandleWorldEvent();

	// handle send pluto
	HandleSendPluto();

	// delete mailbox
	ClearContainer(m_mb4del);
}

void NetService::SendEvent(EventNode *node)
{
	m_net2worldPipe->Push(node);
}

void NetService::CloseMailbox(int fd)
{
	Mailbox *pmb = GetMailboxByFd(fd);
	if (pmb == nullptr)
	{
		LOG_WARN("mailbox null fd=%d", fd);
		return;
	}
	CloseMailbox(pmb);
}

void NetService::CloseMailbox(int64_t mailboxId)
{
	Mailbox *pmb = GetMailboxByMailboxId(mailboxId);
	if (pmb == nullptr)
	{
		LOG_WARN("mailbox null mailboxId=%ld", mailboxId);
		return;
	}
	CloseMailbox(pmb);
}

void NetService::CloseMailbox(Mailbox *pmb)
{
	if (pmb->GetBEV() != nullptr)
	{
		bufferevent_free(pmb->GetBEV());
		pmb->SetBEV(nullptr);
	}
	else
	{
		LOG_WARN("m_bev null %d", pmb->GetMailboxId());
	}

	// notice to world
	EventNodeDisconnect *node = new EventNodeDisconnect();
	node->mailboxId = pmb->GetMailboxId();
	SendEvent(node);

	// push to list, delete by tick
	pmb->SetDeleteFlag();
	m_mb4del.push_back(pmb);
	m_fds.erase(pmb->GetFd());
	m_mailboxs.erase(pmb->GetMailboxId());
}

////////// callback start [

static void listen_cb(struct evconnlistener *listener, evutil_socket_t fd, struct sockaddr *sa, int socklen, void *user_data)
{
	// handle new client connect event
	NetService *ns = (NetService *)user_data;
	ns->HandleNewConnection(fd, sa, socklen);
}

static void read_cb(struct bufferevent *bev, void *user_data)
{
	// handle read event
	NetService *ns = (NetService *)user_data;
	ns->HandleSocketRead(bev);
}

static void event_cb(struct bufferevent *bev, short event, void *user_data)
{
	LOG_DEBUG("******* event=%d", event);
	// handle other event
	NetService *ns = (NetService *)user_data;
	evutil_socket_t fd = bufferevent_getfd(bev);

	if (event & BEV_EVENT_EOF)
	{
		LOG_DEBUG("####### event eof fd=%d", fd);
		ns->HandleSocketClosed(fd);
	}
	else if (event & BEV_EVENT_ERROR)
	{
		LOG_ERROR("!!!!!!! event error fd=%d errno=%d", fd, errno);
		ns->HandleSocketError(fd);
	}
	else if (event & BEV_EVENT_CONNECTED)
	{
		LOG_DEBUG("@@@@@@@ event connected %d", fd);
		ns->HandleSocketConnected(fd);
	}
	else
	{
		LOG_ERROR("??????? unknow event fd=%d event=%d errno=%d", fd, event, errno);
	}
}

static void tick_cb(evutil_socket_t fd, short event, void *user_data)
{
	NetService *server = (NetService *)user_data;
	server->HandleTickEvent();
}

// for add timer
static void timer_cb(evutil_socket_t fd, short event, void *user_data)
{
	// TimerMgr::OnTimer();
	NetService *server = (NetService *)user_data;
	EventNodeTimer *node = new EventNodeTimer();
	server->SendEvent(node);
}

static void stdin_cb(evutil_socket_t fd, short event, void *user_data)
{
	const int MAX_BUFFER = 1024;
	char buffer[MAX_BUFFER+1] = {0};
	int len = read(fd, buffer, MAX_BUFFER+1);
	if (len == 0)
	{
		// EOF
		return;
	}

	if (len > MAX_BUFFER)
	{
		LOG_WARN("stdin buffer too big");
		return;
	}

	if (len < 0)
	{
		LOG_ERROR("read stdin fail");
		return;
	}

	// trim /n
	while (len >= 1 && buffer[len-1] == '\n')
	{
		buffer[len-1] = '\0';
		len -= 1;
	}

	if (len == 0)
	{
		return;
	}

	NetService *server = (NetService *)user_data;

	char *ptr = new char[len+1];
	memcpy(ptr, buffer, len+1);

	EventNodeStdin *node = new EventNodeStdin();
	node->buffer = ptr;
	server->SendEvent(node);
}

////////// callback end ]
