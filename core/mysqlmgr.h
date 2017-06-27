#ifndef _MYSQL_OPERATOR_T_H_
#define _MYSQL_OPERATOR_T_H_

#include <string>
#include "mysql.h"

class MysqlMgr
{
public:
	MysqlMgr();
	~MysqlMgr();

	int Connect(std::string host, int port, std::string username, std::string password, std::string db_name, std::string charset = "utf8");
	int Close();

	// out_buffer size should be 2 * in_buffer size + 1
	int EscapeString(char *out_buffer, const char *in_buffer, int len);

	// query will clean last query result
	int Query(const char *sql, int len);
	int FieldCount();
	int NumRows();
	int AffectedRows();
	MYSQL_ROW FetchRow();
	void CleanResult();

	int GetErr();

private:
	std::string host;
	int port;
	std::string username;
	std::string password;
	std::string db_name;
	std::string charset;

	MYSQL *conn;
	MYSQL_RES *result;
	int err;
	int Reconnect();
	MYSQL * CoreConnect();
};

#endif
