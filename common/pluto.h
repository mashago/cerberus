
#ifndef __PLUTO_H__
#define __PLUTO_H__

enum
{
	MSGLEN_HEAD 	= 4,
	MSGLEN_MSGID 	= 4, 
	MSGLEN_MAX 		= 65000,
	MSGLEN_TEXT_POS = MSGLEN_HEAD + MSGLEN_MSGID,
	
	PLUTO_MSGLEN_HEAD 	= MSGLEN_HEAD,
	PLUTO_FILED_BEGIN_POS 	= MSGLEN_HEAD + MSGLEN_MSGID,
};

class MailBox;

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

	int GetMsgId();

// private:
	char *m_recvBuffer;

	int m_bufferSize;
	int m_msgId;
	int m_recvLen;

	MailBox *m_pmb;
};

#endif
