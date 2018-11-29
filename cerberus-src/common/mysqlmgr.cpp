#include <stdio.h>
#include "util.h"
#include "logger.h"
#include "mysqlmgr.h"

MysqlMgr::MysqlMgr() 
: m_host(""), m_port(0), m_username(""), m_password(""), m_db_name(""), m_charset("")
, conn(NULL), m_result(NULL), m_err(0)
{
}

MysqlMgr::~MysqlMgr()
{
}

MYSQL * MysqlMgr::CoreConnect()
{
	// 1.do mysql_init()
	// 2.set mysql options
	// 3.do mysql_real_connect()
	
	MYSQL *new_conn = NULL;
	new_conn = mysql_init(NULL);  // NULL ?
	if (new_conn == NULL)
	{
		return NULL;
	}

	mysql_options(new_conn, MYSQL_SET_CHARSET_NAME, m_charset.c_str());

	MYSQL *ret_conn;
	ret_conn = mysql_real_connect(new_conn, m_host.c_str(), m_username.c_str(), m_password.c_str(), m_db_name.c_str(), m_port, NULL, 0);
	if (ret_conn == NULL)
	{
		m_err = mysql_errno(new_conn);
		mysql_close(new_conn);
		return NULL;
	}

	return new_conn;
}

int MysqlMgr::Connect(std::string host, int port, std::string username, std::string password, std::string db_name, std::string charset)
{
	m_host = host;
	m_port = port;
	m_username = username;
	m_password = password;
	m_db_name = db_name;
	m_charset = charset;

	if (conn != NULL)
	{
		return -1;
	}
	conn = CoreConnect();
	if (conn == NULL)
	{
		return -2;
	}
	return 0;
}

void MysqlMgr::Close()
{
	if (conn != NULL)
	{
		CleanResult();
		mysql_close(conn);
		conn = NULL;
	}
}

int MysqlMgr::Reconnect()
{
	MYSQL *new_conn = NULL;
	new_conn = CoreConnect();
	if (new_conn == NULL)
	{
		return -1;
	}
	Close();
	conn = new_conn;
	return 0;
}

int MysqlMgr::EscapeString(char *out_buffer, const char *in_buffer, int len)
{
	return mysql_real_escape_string(conn, out_buffer, in_buffer, len);
}

int MysqlMgr::CoreQuery(const char *sql, int len, bool is_select)
{
	// 1.clean mysql m_result
	// 2.do mysql_real_query
	// 3.do mysql_store_result, event sql is not a select
	// 4.if error is disconnect, Reconnect and try again
	
	CleanResult();
	
	int ret = 0;
	int reconn_count = 0;
	do
	{
		if (conn != NULL)
		{
			ret = mysql_real_query(conn, sql, len);
			if (ret == 0)
			{
				if (is_select)
				{
					m_result = mysql_store_result(conn); 
				}
				else
				{
					// select query will return -1, so have to split select and change
					ret = mysql_affected_rows(conn);
				}
				return ret;
			}
		}

		ret = -1;

		m_err = 8888; // 8888 for connect null

		if (conn != NULL)
		{
			m_err = mysql_errno(conn);
		}

		if (m_err == 2013 || m_err == 2006 || m_err == 8888)
		{
			LOG_ERROR("CoreQuery:disconnect errno=%d", m_err);
			sleep(1);
			Reconnect();
			reconn_count++;
		}
		else
		{
			// execute error
			return ret;
		}
	}
	while (reconn_count < 3);

	return ret;
}

int MysqlMgr::Select(const char *sql, int len)
{
	return CoreQuery(sql, len, true);
}

int MysqlMgr::Change(const char *sql, int len)
{
	return CoreQuery(sql, len, false);
}

int MysqlMgr::FieldCount()
{
	if (conn == NULL)
	{
		return -1;
	}

	return mysql_field_count(conn);
}

int MysqlMgr::NumRows()
{
	if (conn == NULL)
	{
		return -1;
	}

	if (m_result == NULL)
	{
		return -1;
	}

	return mysql_num_rows(m_result);
}

/*
int MysqlMgr::AffectedRows()
{
	if (conn == NULL)
	{
		return -1;
	}

	return mysql_affected_rows(conn);
}
*/

int64_t MysqlMgr::GetInsertId()
{
	if (conn == NULL)
	{
		return -1;
	}
	return mysql_insert_id(conn);

}

MYSQL_FIELD * MysqlMgr::FetchField()
{
	if (conn == NULL)
	{
		return NULL;
	}

	if (m_result == NULL)
	{
		return NULL;
	}

	return mysql_fetch_fields(m_result);
}

MYSQL_ROW MysqlMgr::FetchRow()
{
	MYSQL_ROW row = NULL;
	if (conn == NULL)
	{
		return row;
	}

	if (m_result == NULL)
	{
		return row;
	}

	row = mysql_fetch_row(m_result);

	return row;
}

void MysqlMgr::CleanResult()
{
	m_err = 0;

	if (m_result != NULL)
	{
		mysql_free_result(m_result);
		m_result = NULL;
	}

	while(!mysql_next_result(conn))
	{
		m_result = mysql_store_result(conn);
		mysql_free_result(m_result);
	} 

	m_result = NULL;
}

int MysqlMgr::GetErrno()
{
	return m_err;
}

const char * MysqlMgr::GetError()
{
	if (!conn) return NULL;
	return mysql_error(conn);
}

