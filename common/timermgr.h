
#pragma once

#include <stdint.h>

class TimerMgr
{
public:
	static int64_t AddTimer();
	static bool DelTimer();
private:
	static int64_t m_timerIndex;

};
