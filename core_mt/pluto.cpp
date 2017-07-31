
#ifdef WIN32
#include<Winsock2.h>
#else
#include <arpa/inet.h>
#endif
#include <string.h>
#include <string>

#include "pluto.h"
#include "logger.h"

Pluto::Pluto(int bufferSize) : m_buffer(nullptr), m_cursor(nullptr), m_bufferSize(bufferSize), m_recvLen(0)
{
	m_buffer = new char[m_bufferSize];
	m_cursor = m_buffer + MSGLEN_TEXT_POS;
}

Pluto::~Pluto()
{
	delete [] m_buffer;
}

int Pluto::GetMsgLen() const
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

char * Pluto::GetBuffer()
{
	return m_buffer;
}

char * Pluto::GetContent()
{
	return m_buffer + MSGLEN_TEXT_POS;
}

int Pluto::GetContentLen()
{
	return GetMsgLen() - MSGLEN_TEXT_POS;
}

void Pluto::ResetCursor()
{
	m_cursor = m_buffer + MSGLEN_TEXT_POS;
}

//////////////////////////////////////////////

void Pluto::WriteMsgId(int msgId)
{
	*(uint32_t *)(m_buffer+MSGLEN_HEAD) = htonl(msgId);
}

void Pluto::WriteExt(int ext)
{
	*(uint32_t *)(m_buffer+MSGLEN_HEAD+MSGLEN_MSGID) = htonl(ext);
}

#define write_val(val) \
do { \
if (m_cursor + sizeof(val) - m_buffer > m_bufferSize) { return false; } \
memcpy(m_cursor, &val, sizeof(val)); \
m_cursor += sizeof(val); \
} while (false)


bool Pluto::WriteByte(char val)
{
	write_val(val);
	return true;
}

bool Pluto::WriteInt(int val)
{
	write_val(val);
	return true;
}

bool Pluto::WriteFloat(float val)
{
	write_val(val);
	return true;
}

bool Pluto::WriteBool(bool val)
{
	WriteByte(val ? '1' : '0');
	return true;
}

bool Pluto::WriteShort(short val)
{
	write_val(val);
	return true;
}

bool Pluto::WriteInt64(int64_t val)
{
	write_val(val);
	return true;
}

bool Pluto::WriteString(int len, const char* str)
{
	if (!WriteInt(len))
	{
		return false;
	}

	if (m_cursor + len > m_buffer + m_bufferSize)
	{
		return false;
	}

	memcpy(m_cursor, str, len);
	m_cursor += len;
	return true;
}

////////////////////////////////////////////////

int Pluto::ReadMsgId()
{
	return (int)ntohl(*(uint32_t *)(m_buffer + MSGLEN_HEAD));
}

int Pluto::ReadExt()
{
	return (int)ntohl(*(uint32_t *)(m_buffer + MSGLEN_HEAD + MSGLEN_MSGID));
}

template<typename T>
bool read_val(char * &cursor, const char *buffer_end, T &out_val)
{
	if (cursor + sizeof(T) > buffer_end)
	{
		return false;
	}
	out_val = *((T *)(cursor));
	cursor += sizeof(T);
	return true;
}

bool Pluto::ReadByte(char &out_val)
{
	return read_val<char>(m_cursor, m_buffer + m_bufferSize, out_val);
}

bool Pluto::ReadInt(int &out_val)
{
	return read_val<int>(m_cursor, m_buffer + m_bufferSize, out_val);
}

bool Pluto::ReadFloat(float &out_val)
{
	return read_val<float>(m_cursor, m_buffer + m_bufferSize, out_val);
}

bool Pluto::ReadBool(bool &out_val)
{
	char val = '0';
	if (!read_val<char>(m_cursor, m_buffer + m_bufferSize, val))
	{
		return false;
	}
	out_val = (val == '1');
	return true;
}

bool Pluto::ReadShort(short &out_val)
{
	return read_val<short>(m_cursor, m_buffer + m_bufferSize, out_val);
}

bool Pluto::ReadInt64(int64_t &out_val)
{
	return read_val<int64_t>(m_cursor, m_buffer + m_bufferSize, out_val);
}

bool Pluto::ReadString(int &out_len, char *out_val)
{
	if (!ReadInt(out_len))
	{
		return false;
	}

	if (m_cursor + out_len > m_buffer + m_bufferSize)
	{
		return false;
	}

	memcpy(out_val, m_cursor, out_len);
	m_cursor += out_len;
	return true;
}


void Pluto::Print()
{
	LOG_DEBUG("bufferSize=[%d] msgLen=[%d] msgId=[%d]", m_bufferSize, GetMsgLen(), ReadMsgId());
}

Pluto *Pluto::Clone()
{
	int len = GetMsgLen();
	Pluto *pu = new Pluto(len);
	char *buffer = pu->GetBuffer();
	memcpy(buffer, m_buffer, len);
	return pu;
}

void Pluto::Copy(const Pluto *pu)
{
	int len = pu->GetMsgLen();
	char *buffer = const_cast<Pluto *>(pu)->GetBuffer();
	memcpy(m_buffer, buffer, len);
	m_cursor = m_buffer + len; // update m_cursor pos to buffer end, for SetMsgLen right
}
