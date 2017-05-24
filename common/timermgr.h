
#pragma once

extern "C"
{
#include <stdint.h>
}
#include <map>

class NetService;

class TimerMgr
{
public:
	typedef void (*TIMER_CB)(void *);
	static void Init(NetService *net);
	static int64_t AddTimer(int ms, TIMER_CB cb_func, void *arg, bool is_loop);
	static bool DelTimer();
	static void WakeUp(void *data);
private:
	struct Timer
	{
		bool _is_loop;
		void *_arg;
		TIMER_CB _cb_func;
	};

	static std::map<int64_t, Timer> m_timerMap;
	static int64_t m_timerIndex;
	static NetService *m_net;

};
