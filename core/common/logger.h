
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

#define NOT_USE_LOGGER 0

#if (NOT_USE_LOGGER == 1)
void _logcore(int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...);

#define LOG_INIT(log_file_name, is_print_log) do {} while (false)
#define LOG_DEBUG(fmt, ...) _logcore(LOG_TYPE_DEBUG, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_INFO(fmt, ...) _logcore(LOG_TYPE_INFO, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_WARN(fmt, ...) _logcore(LOG_TYPE_WARN, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) _logcore(LOG_TYPE_ERROR, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_RAW(type, filename, funcname, linenum, fmt, ...) _logcore(type, filename, funcname, linenum, fmt, ##__VA_ARGS__);
#define LOG_STOP() do {} while (false)

#else

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
	void Init(const char *log_file_name, bool is_print_log = true);
	void SendLog(int type, const char *filename, const char *funcname, int linenum, const char *fmt, ...);
	void SendLogStr(int type, const char *filename, const char *funcname, int linenum, const char *content_buffer);
	void Stop();


private:
	Logger();
	~Logger();
	void PrintLog(const char *buffer);
	void RecvLog();
	void ShiftLogFile();

	LogPipe m_logPipe;
	std::string m_logFileName;
	bool m_isRunning;
	bool m_isWriteLog;
	bool m_isPrintLog;
	std::thread m_logThread;
};

#define LOG_INIT(log_file_name, is_print_log) Logger::Instance()->Init(log_file_name, is_print_log)
#define LOG_DEBUG(fmt, ...) Logger::Instance()->SendLog(LOG_TYPE_DEBUG, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_INFO(fmt, ...) Logger::Instance()->SendLog(LOG_TYPE_INFO, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_WARN(fmt, ...) Logger::Instance()->SendLog(LOG_TYPE_WARN, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) Logger::Instance()->SendLog(LOG_TYPE_ERROR, __FILE__, __FUNCTION__, __LINE__, fmt, ##__VA_ARGS__)
#define LOG_RAW(type, filename, funcname, linenum, fmt, ...) Logger::Instance()->SendLog(type, filename, funcname, linenum, fmt, ##__VA_ARGS__)
#define LOG_RAW_STRING(type, filename, funcname, linenum, str) Logger::Instance()->SendLogStr(type, filename, funcname, linenum, str)
#define LOG_STOP() Logger::Instance()->Stop()

#endif
