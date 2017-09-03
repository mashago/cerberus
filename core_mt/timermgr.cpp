
#ifndef WIN32
#include <sys/time.h>
#endif
#include "util.h"
#include "logger.h"
#include "timermgr.h"

TimerMgr::TimerMgr() : m_timerIndex(0)
{
}

TimerMgr::~TimerMgr()
{
}

int64_t TimerMgr::GetCurTimerIndex()
{
	return TimerMgr::m_timerIndex;
}

int64_t TimerMgr::AddTimer(int ms, TIMER_CB cb_func, void *arg, bool is_loop)
{
	++m_timerIndex;
	struct timeval tv;
	gettimeofday(&tv, NULL);

	Timer t;
	t._ms = ms;
	t._wake_time = tv.tv_sec * 1000 + tv.tv_usec / 1000 + ms;
	t._is_loop = is_loop;
	t._arg = arg;
	t._cb_func = cb_func;
	m_timerMap[m_timerIndex] = t;

	TimerOrderNode n;
	n._wake_time = t._wake_time;
	n._timer_index = m_timerIndex;
	m_timerOrderQueue.push(n);

	return m_timerIndex;
}

bool TimerMgr::DelTimer(int64_t timer_index)
{
	m_timerDelList.push_back(timer_index);
	return true;
}

void TimerMgr::OnTimer()
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	int64_t now_time = tv.tv_sec * 1000 + tv.tv_usec / 1000;
	// LOG_DEBUG("now_time=%lld", now_time);

	// new logic
	/*
	while (!m_timerOrderQueue.empty())
	{
		const TimerOrderNode &n = m_timerOrderQueue.top();
		if (n._wake_time > now_time)
		{
			break;
		}

		int64_t wake_time = n._wake_time;
		int64_t timer_index = n._timer_index;
		m_timerOrderQueue.pop();

		auto iter = m_timerMap.find(timer_index);
		if (iter == m_timerMap.end())
		{
			// XXX something go wrong
			continue;
		}
		
		Timer &timer = iter->second;
		timer._cb_func(timer._arg);
		if (timer._is_loop)
		{
			timer._wake_time = now_time + timer._ms;

			TimerOrderNode n;
			n._wake_time = timer._wake_time;
			n._timer_index = timer_index;
			m_timerOrderQueue.push(n);
			continue;
		}

		// one time job timer
		DelTimer(timer_index);

	}
	*/

	// TODO change to priority_queue
	for (auto iter = m_timerMap.begin(); iter != m_timerMap.end(); ++iter)
	{

		// LOG_DEBUG("start loop timer map");
		Timer &timer = iter->second;
		if (timer._wake_time > now_time)
		{
			continue;
		}
		
		timer._cb_func(timer._arg);
		if (timer._is_loop)
		{
			timer._wake_time = now_time + timer._ms;
			continue;
		}

		// one time job timer
		DelTimer(iter->first);
	}

	for (auto iter = m_timerDelList.begin(); iter != m_timerDelList.end(); ++iter)
	{
		m_timerMap.erase(*iter);
	}
	m_timerDelList.clear();
	
}


