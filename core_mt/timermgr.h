
#pragma once

extern "C"
{
#include <stdint.h>
}
#include <functional>
#include <map>
#include <list>

class NetService;

class TimerMgr
{
public:
	// typedef void (*TIMER_CB)(void *);
	typedef std::function<void(void*)> TIMER_CB;
	TimerMgr();
	~TimerMgr();

	int64_t GetCurTimerIndex();
	int64_t AddTimer(int ms, TIMER_CB cb_func, void *arg, bool is_loop);
	bool DelTimer(int64_t timer_index);
	void OnTimer();
private:
	
	struct Timer
	{
		int _ms;
		int64_t _wake_time; // ms
		bool _is_loop;
		void *_arg;
		TIMER_CB _cb_func;
	};

	std::map<int64_t, Timer> m_timerMap;
	std::list<int64_t> m_timerDelList;
	int64_t m_timerIndex;

};
