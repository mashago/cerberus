
#include <arpa/inet.h>
#include <string.h>
#include <string>

#include "pluto.h"
#include "logger.h"

Pluto::Pluto(int bufferSize) : m_buffer(nullptr), m_cursor(nullptr), m_bufferSize(bufferSize), m_recvLen(0)
{
	m_buffer = new char[m_bufferSize];
	m_cursor = m_buffer + PLUTO_FILED_BEGIN_POS;
}

Pluto::~Pluto()
{
	delete [] m_buffer;
}

int Pluto::GetMsgLen()
{
	return (int)ntohl(*(uint32_t *)(m_buffer));
}

void Pluto::SetMsgLen(int len)
{
	if (len == 0)
	{
		*(uint32_t *)m_buffer = htonl(m_cursor - m_buffer);
	}
	else
	{
		*(uint32_t *)m_buffer = htonl(len);
	}
}

int Pluto::GetMsgId()
{
	return (int)ntohl(*(uint32_t *)(m_buffer + PLUTO_MSGLEN_HEAD));
}

void Pluto::SetMsgId(int msgId)
{
	*(uint32_t *)(m_buffer+PLUTO_MSGLEN_HEAD) = htonl(msgId);
}

char * Pluto::GetBuffer()
{
	return m_buffer;
}

char * Pluto::GetContent()
{
	return m_buffer + PLUTO_FILED_BEGIN_POS;
}

int Pluto::GetContentLen()
{
	return GetMsgLen() - PLUTO_FILED_BEGIN_POS;
}

void Pluto::ResetCursor()
{
	m_cursor = m_buffer + PLUTO_FILED_BEGIN_POS;
}

#define write_val(val) \
do { \
if (m_cursor + sizeof(val) - m_buffer > m_bufferSize) { return; } \
memcpy(m_cursor, &val, sizeof(val)); \
m_cursor += sizeof(val); \
} while (false)


void Pluto::WriteByte(char val)
{
	write_val(val);
}

void Pluto::WriteInt(int val)
{
	write_val(val);
}

void Pluto::WriteFloat(float val)
{
	write_val(val);
}

void Pluto::WriteBool(bool val)
{
	WriteByte(val ? '1' : '0');
}

void Pluto::WriteShort(short val)
{
	write_val(val);
}

void Pluto::WriteInt64(int64_t val)
{
	write_val(val);
}

void Pluto::WriteString(const char* str, short len)
{
	if (m_cursor + sizeof(len) - m_buffer > m_bufferSize) { return; }
	memcpy(m_cursor, &len, sizeof(len));
	m_cursor += sizeof(len);

	if (m_cursor + len - m_buffer > m_bufferSize) { return; }
	memcpy(m_cursor, str, len);
	m_cursor += len;
}

template<typename T>
T read_val(char * &cursor)
{
	T out_val = *((T *)(cursor));
	cursor += sizeof(T);
	return out_val;
}

char Pluto::ReadByte()
{
	char out_val = read_val<char>(m_cursor);
	return out_val;
}

int Pluto::ReadInt()
{
	int out_val = read_val<int>(m_cursor);
	return out_val;
}

float Pluto::ReadFloat()
{
	float out_val = read_val<float>(m_cursor);
	return out_val;
}

bool Pluto::ReadBool()
{
	char out_val = read_val<char>(m_cursor);
	return out_val != '1';
}

short Pluto::ReadShort()
{
	short out_val = read_val<short>(m_cursor);
	return out_val;
}

int64_t Pluto::ReadInt64()
{
	int64_t out_val = read_val<int64_t>(m_cursor);
	return out_val;
}

short Pluto::ReadString(char *out_val)
{
	short len = ReadShort();
	memcpy(out_val, m_cursor, len);
	m_cursor += len;
	return len;
}


void Pluto::Print()
{
	// std::string content(GetContent(), GetContentLen());
	// LOG_DEBUG("bufferSize=[%d] msgLen=[%d] msgId=[%d] buffer=[%s]", m_bufferSize, GetMsgLen(), GetMsgId(), content.c_str());
}
