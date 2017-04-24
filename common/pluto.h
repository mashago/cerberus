
#ifndef __PLUTO_H__
#define __PLUTO_H__

#include <stdint.h>

enum
{
	MSGLEN_HEAD 	= 4,
	MSGLEN_MSGID 	= 4, 
	MSGLEN_MAX 		= 65000,
	MSGLEN_TEXT_POS = MSGLEN_HEAD + MSGLEN_MSGID,
	
	PLUTO_MSGLEN_HEAD 	= MSGLEN_HEAD,
	PLUTO_FILED_BEGIN_POS 	= MSGLEN_HEAD + MSGLEN_MSGID,
};

class Mailbox;

/*
 * msg:
 * [msgLen:4] [msgId:4] [content] 
 * msgLen is total msg len, msgLen size + msgId size + content size
 *
 */

class Pluto
{
public:

	Pluto(int bufferSize);
	~Pluto();

	int GetMsgLen();
	void SetMsgLen(int len = 0);

	int GetMsgId();
	void SetMsgId(int msgId);

	char * GetBuffer();
	char * GetContent();
	int GetContentLen();

	int GetRecvLen()
	{
		return m_recvLen;
	}

	void SetRecvLen(int len)
	{
		m_recvLen = len;
	}

	Mailbox *GetMailbox()
	{
		return m_pmb;
	}

	void SetMailbox(Mailbox *ptr)
	{
		m_pmb = ptr;
	}

	void InitCursor();

	void WriteByte(char val);
	void WriteInt(int val);
	void WriteFloat(float val);
	void WriteBool(bool val);
	void WriteShort(short val);
	void WriteInt64(int64_t val);
	void WriteString(const char* str, unsigned short len);

	char ReadByte();
	int ReadInt();
	float ReadFloat();
	bool ReadBool();
	short ReadShort();
	int64_t ReadInt64();
	bool ReadString(char *out_val);

	void Print();

private:
	char *m_buffer;
	char *m_cursor;

	int m_bufferSize;
	int m_recvLen;

	Mailbox *m_pmb;
};

#endif
