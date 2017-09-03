
#pragma once

extern "C"
{
#include <stdint.h>
}
#include <functional>
#include <map>
#include <queue>

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

	void AddTimerOrder(int64_t wake_time, int64_t timer_index);
	
	struct Timer
	{
		int _ms;
		bool _is_loop;
		void *_arg;
		TIMER_CB _cb_func;
	};

	std::map<int64_t, Timer> m_timerMap;

	struct TimerOrderNode
	{
		int64_t _wake_time; // ms
		int64_t _timer_index;
		friend bool operator<(const TimerOrderNode &n1, const TimerOrderNode &n2)
		{
			return n1._wake_time > n2._wake_time;
		}
	};
	std::priority_queue<TimerOrderNode> m_timerOrderQueue;

	int64_t m_curTimerIndex;
};
