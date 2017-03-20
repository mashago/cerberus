
#include <arpa/inet.h>
#include "pluto.h"

Pluto::Pluto(int bufferSize) : m_recvBuffer(nullptr), m_bufferSize(bufferSize), m_msgId(0), m_recvLen(0)
{
	m_recvBuffer = new char[m_bufferSize];
}

Pluto::~Pluto()
{
	delete [] m_recvBuffer;
}

int Pluto::GetMsgId()
{
	return (int)ntohl(*(uint32_t *)(m_recvBuffer + PLUTO_MSGLEN_HEAD));
}
