
#pragma once

extern "C"
{
#include <stdint.h>
}
#include <map>
#include <list>

class NetService;

class TimerMgr
{
public:
	typedef void (*TIMER_CB)(void *);
	static int64_t GetCurTimerIndex();
	static int64_t AddTimer(int ms, TIMER_CB cb_func, void *arg, bool is_loop);
	static bool DelTimer(int64_t timer_index);
	static void OnTimer();
private:
	struct Timer
	{
		int _ms;
		int64_t _wake_time; // ms
		bool _is_loop;
		void *_arg;
		TIMER_CB _cb_func;
	};

	static std::map<int64_t, Timer> m_timerMap;
	static std::list<int64_t> m_timerDelList;
	static int64_t m_timerIndex;

};
