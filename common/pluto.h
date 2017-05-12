
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

	void ResetCursor();


	void WriteMsgId(int msgId);
	bool WriteByte(char val);
	bool WriteInt(int val);
	bool WriteFloat(float val);
	bool WriteBool(bool val);
	bool WriteShort(short val);
	bool WriteInt64(int64_t val);
	bool WriteString(int len, const char* str);

	int  ReadMsgId();
	bool ReadByte(char &out_val);
	bool ReadInt(int &out_val);
	bool ReadFloat(float &out_val);
	bool ReadBool(bool &out_val);
	bool ReadShort(short &out_val);
	bool ReadInt64(int64_t &out_val);
	bool ReadString(int &out_len, char *out_val);

	Pluto *Clone();

	void Print();

private:
	char *m_buffer;
	char *m_cursor;

	int m_bufferSize;
	int m_recvLen;

	Mailbox *m_pmb;
};

#endif
