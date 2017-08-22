
#pragma once

#include <list>
#include <utility>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <memory>
#include <string>

#include "util.h"

enum
{
	LOG_TYPE_DEBUG = 1,
	LOG_TYPE_INFO = 2,
	LOG_TYPE_WARN = 3,
	LOG_TYPE_ERROR = 4,
};

void _logcore(int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...);

#define LOG_DEBUG(fmt, ...) _logcore(LOG_TYPE_DEBUG, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_INFO(fmt, ...) _logcore(LOG_TYPE_INFO, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_WARN(fmt, ...) _logcore(LOG_TYPE_WARN, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) _logcore(LOG_TYPE_ERROR, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)

class LogPipe
{
public:
	LogPipe();
	~LogPipe();
	LogPipe(const LogPipe &) = delete;
	LogPipe & operator=(const LogPipe &) = delete;

	void Push(const char *buffer);
	const std::list<const char *> & Pop();

private:
	std::mutex m_mtx;
	std::condition_variable m_cv;
	SwitchList<const char *> m_eventList;

	void Switch();
};

class Logger
{
public:
	static Logger *Instance();
	void Init(const char *log_file_name);
	void SendLog(int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...);
	void RecvLog();
private:
	Logger();
	~Logger();
	LogPipe m_logPipe;
	std::string m_logFileName;
};
