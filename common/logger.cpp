
#include <stdarg.h>
#include <stdio.h>
#include "logger.h"

void __log(const char *title, const char *fmt, va_list ap)
{
	enum {MAX_LOG_BUFFER_SIZE = 1024};
	char buffer[MAX_LOG_BUFFER_SIZE];
	vsnprintf(buffer, MAX_LOG_BUFFER_SIZE, fmt, ap);

	printf("%s %s\n", title, buffer);
}

void LogDebug(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	__log("DEBUG", fmt, ap);
	va_end(ap);
}

void LogInfo(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	__log("INFO", fmt, ap);
	va_end(ap);
}

void LogWarn(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	__log("WARN", fmt, ap);
	va_end(ap);
}

void LogError(const char *fmt, ...)
{
	va_list ap;
	va_start(ap, fmt);
	__log("ERROR", fmt, ap);
	va_end(ap);
}
