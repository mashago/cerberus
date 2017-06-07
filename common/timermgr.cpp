
#include "logger.h"
#include "timermgr.h"
#include "net_service.h"

std::map<int64_t, TimerMgr::Timer> TimerMgr::m_timerMap;
int64_t TimerMgr::m_timerIndex = 0;

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

	return m_timerIndex;
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

	for (auto iter = m_timerMap.begin(); iter != m_timerMap.end();)
	{
		Timer &timer = iter->second;
		if (timer._wake_time > now_time)
		{
			++iter;
			continue;
		}
		
		timer._cb_func(timer._arg);
		if (timer._is_loop)
		{
			timer._wake_time = now_time + timer._ms;
			++iter;
			continue;
		}

		// need del timer
		auto del_iter = iter++;
		m_timerMap.erase(del_iter);
	}

}


