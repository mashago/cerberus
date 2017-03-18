
#include "pluto.h"

Pluto::Pluto(int bufferSize) : m_recvLen(0)
{
	m_recvBuffer = new char[bufferSize];
	m_bufferSize = bufferSize;
}

Pluto::~Pluto()
{
	delete m_recvBuffer;
}
