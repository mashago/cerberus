
#include <arpa/inet.h>
#include <string>

#include "pluto.h"
#include "logger.h"

Pluto::Pluto(int bufferSize) : m_recvBuffer(nullptr), m_bufferSize(bufferSize), m_msgId(0), m_recvLen(0)
{
	m_recvBuffer = new char[m_bufferSize];
}

Pluto::~Pluto()
{
	delete [] m_recvBuffer;
}

int Pluto::GetLen()
{
	return (int)ntohl(*(uint32_t *)(m_recvBuffer));
}

int Pluto::GetMsgId()
{
	return (int)ntohl(*(uint32_t *)(m_recvBuffer + PLUTO_MSGLEN_HEAD));
}

char * Pluto::GetBuffer()
{
	return m_recvBuffer;
}

char * Pluto::GetContent()
{
	return m_recvBuffer + PLUTO_FILED_BEGIN_POS;
}

int Pluto::GetContentLen()
{
	return GetLen() - PLUTO_FILED_BEGIN_POS;
}

void Pluto::Print()
{
	std::string content(GetContent(), GetContentLen());
	LOG_DEBUG("bufferSize=[%d] msgLen=[%d] msgId=[%d] buffer=[%s]", m_bufferSize, GetLen(), GetMsgId(), content.c_str());
}
