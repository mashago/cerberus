
#ifndef __PLUTO_H__
#define __PLUTO_H__

#define MAX_PLUTO_RECV_BUFFER 500

class Pluto
{
public:
	Pluto();
	~Pluto();

private:
	char m_recvBuffer[MAX_PLUTO_RECV_BUFFER];
	int m_recvPos;
};

#endif
