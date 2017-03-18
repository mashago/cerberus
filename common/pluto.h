
#ifndef __PLUTO_H__
#define __PLUTO_H__

enum
{
	MSGLEN_HEAD 	= 4,
	MSGLEN_MSGID 	= 4, 
	MSGLEN_MAX 		= 65000,
	
	PLUTO_MSGLEN_HEAD 	= MSGLEN_HEAD,
	PLUTO_FILED_BEGIN_POS 	= MSGLEN_HEAD + MSGLEN_MSGID,
};

class MailBox;
class Pluto
{
public:

	Pluto(int bufferSize);
	~Pluto();

// private:
	char *m_recvBuffer;
	int m_bufferSize;
	int m_recvLen;
	MailBox *m_pmb;
};

#endif
