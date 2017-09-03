
#ifndef WIN32
#include <sys/time.h>
#endif
#include "util.h"
#include "logger.h"
#include "timermgr.h"

TimerMgr::TimerMgr() : m_curTimerIndex(1)
{
}

TimerMgr::~TimerMgr()
{
}

int64_t TimerMgr::GetCurTimerIndex()
{
	return m_curTimerIndex;
}

int64_t TimerMgr::AddTimer(int ms, TIMER_CB cb_func, void *arg, bool is_loop)
{
	struct timeval tv;
	gettimeofday(&tv, NULL);

	Timer t;
	t._ms = ms;
	t._is_loop = is_loop;
	t._arg = arg;
	t._cb_func = cb_func;
	m_timerMap[m_curTimerIndex] = t;

	AddTimerOrder(tv.tv_sec * 1000 + tv.tv_usec / 1000 + ms, m_curTimerIndex);

	return m_curTimerIndex++;
}

void TimerMgr::AddTimerOrder(int64_t wake_time, int64_t timer_index)
{
	TimerOrderNode n;
	n._wake_time = wake_time;
	n._timer_index = timer_index;
	m_timerOrderQueue.push(n);
}

bool TimerMgr::DelTimer(int64_t timer_index)
{
	m_timerMap.erase(timer_index);
	return true;
}

void TimerMgr::OnTimer()
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	int64_t now_time = tv.tv_sec * 1000 + tv.tv_usec / 1000;
	// LOG_DEBUG("now_time=%lld", now_time);

	// new logic
	while (!m_timerOrderQueue.empty())
	{
		const TimerOrderNode &n = m_timerOrderQueue.top();
		if (n._wake_time > now_time)
		{
			break;
		}

		int64_t timer_index = n._timer_index;
		m_timerOrderQueue.pop();

		auto iter = m_timerMap.find(timer_index);
		if (iter == m_timerMap.end())
		{
			// timer already erase, normal
			continue;
		}
		
		Timer timer = iter->second;
		timer._cb_func(timer._arg); // timer may erase inside

		if (!timer._is_loop)
		{
			// erase one time job timer
			m_timerMap.erase(timer_index);
			continue;
		}

		AddTimerOrder(now_time + timer._ms, timer_index);
	}
}


