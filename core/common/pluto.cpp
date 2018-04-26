
#ifdef WIN32
// #include<Winsock2.h>
#else
// #include <arpa/inet.h>
#endif
#include <string.h>
#include <string>

#include "common.h"
#include "pluto.h"
#include "logger.h"

Pluto::Pluto(int bufferSize) : m_buffer(nullptr), m_cursor(nullptr), m_bufferSize(bufferSize), m_recvLen(0)
{
	m_buffer = new char[m_bufferSize];
	m_cursor = m_buffer + MSGLEN_CONTENT_POS;
}

Pluto::~Pluto()
{
	delete [] m_buffer;
}

int Pluto::GetMsgLen() const
{
	return *(int *)(m_buffer);
}

void Pluto::SetMsgLen(int len)
{
	if (len == 0)
	{
		*(int *)m_buffer = int(m_cursor - m_buffer);
	}
	else
	{
		*(int *)m_buffer = len;
	}
}

char * Pluto::GetBuffer()
{
	return m_buffer;
}

char * Pluto::GetContent()
{
	return m_buffer + MSGLEN_CONTENT_POS;
}

int Pluto::GetContentLen()
{
	return GetMsgLen() - MSGLEN_CONTENT_POS;
}

void Pluto::ResetCursor()
{
	m_cursor = m_buffer + MSGLEN_CONTENT_POS;
}

void Pluto::Cleanup()
{
	ResetCursor();
	memset(m_buffer, 0, MSGLEN_HEADER);
}

//////////////////////////////////////////////

void Pluto::WriteMsgId(int msgId)
{
	*(int *)(m_buffer+MSGLEN_SIZE) = msgId;
}

void Pluto::WriteExt(int64_t ext)
{
	*(int64_t *)(m_buffer+MSGLEN_SIZE+MSGLEN_MSGID) = ext;
}

#define write_val(val, ret) \
do { \
	if (m_cursor + sizeof(val) - m_buffer > m_bufferSize) \
	{ \
		ret = false; \
		break; \
	} \
	memcpy(m_cursor, &val, sizeof(val)); \
	m_cursor += sizeof(val); \
} while (false)


bool Pluto::WriteByte(char val)
{
	bool ret = true;
	write_val(val, ret);
	return ret;
}

bool Pluto::WriteInt(int val)
{
	bool ret = true;
	write_val(val, ret);
	return ret;
}

bool Pluto::WriteFloat(float val)
{
	bool ret = true;
	write_val(val, ret);
	return ret;
}

bool Pluto::WriteBool(bool val)
{
	return WriteByte(val ? '1' : '0');
}

bool Pluto::WriteShort(short val)
{
	bool ret = true;
	write_val(val, ret);
	return ret;
}

bool Pluto::WriteInt64(int64_t val)
{
	bool ret = true;
	write_val(val, ret);
	return ret;
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
	return *(int *)(m_buffer + MSGLEN_SIZE);
}

int64_t Pluto::ReadExt()
{
	return *(int64_t *)(m_buffer + MSGLEN_SIZE + MSGLEN_MSGID);
}

#define read_val(out_val, ret) \
do { \
	if (m_cursor + sizeof(out_val) - m_buffer > m_bufferSize) \
	{ \
		ret = false; \
		break; \
	} \
	memcpy(&out_val, m_cursor, sizeof(out_val)); \
	m_cursor += sizeof(out_val); \
} while (false)

bool Pluto::ReadByte(char &out_val)
{
	bool ret = true;
	read_val(out_val, ret);
	return ret;
}

bool Pluto::ReadInt(int &out_val)
{
	bool ret = true;
	read_val(out_val, ret);
	return ret;
}

bool Pluto::ReadFloat(float &out_val)
{
	bool ret = true;
	read_val(out_val, ret);
	return ret;
}

bool Pluto::ReadBool(bool &out_val)
{
	bool ret = true;
	char val = '0';
	ret = ReadByte(val);
	out_val = (val == '1');
	return ret;
}

bool Pluto::ReadShort(short &out_val)
{
	bool ret = true;
	read_val(out_val, ret);
	return ret;
}

bool Pluto::ReadInt64(int64_t &out_val)
{
	bool ret = true;
	read_val(out_val, ret);
	return ret;
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

