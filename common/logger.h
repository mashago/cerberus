
#ifndef __LOGGER_H__
#define __LOGGER_H__

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

#endif
