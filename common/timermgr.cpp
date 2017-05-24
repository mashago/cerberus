
#include "logger.h"
#include "timermgr.h"
#include "net_service.h"

std::map<int64_t, TimerMgr::Timer> TimerMgr::m_timerMap;
int64_t TimerMgr::m_timerIndex = 0;
NetService *TimerMgr::m_net = nullptr;

void TimerMgr::Init(NetService *net)
{
	m_net = net;
}

int64_t TimerMgr::AddTimer(int ms, TIMER_CB cb_func, void *arg, bool is_loop)
{
	++m_timerIndex;

	Timer t;
	t._is_loop = is_loop;
	t._arg = arg;
	t._cb_func = cb_func;

	m_timerMap[m_timerIndex] = t;

	int64_t *pindex = new int64_t(m_timerIndex);
	m_net->AddTimer(ms, is_loop, (void *)pindex);

	return m_timerIndex;
}

bool TimerMgr::DelTimer()
{
	return true;
}

void TimerMgr::WakeUp(void *data)
{
	int64_t *pindex = (int64_t *)data;
	int64_t index = *pindex;
	auto iter = m_timerMap.find(index);
	if (iter == m_timerMap.end())
	{
		LOG_WARN("timer nil %lld", index);
		// should we delete timer?
		delete pindex;
		return;
	}
	Timer t = iter->second;
	t._cb_func(t._arg);

	if (!t._is_loop)
	{
		m_timerMap.erase(iter);
		delete pindex;
	}
}


