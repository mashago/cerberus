
#include <set>
#include <string>

#include "logger.h"
#include "tinyxml2.h"
#include "mysqlmgr.h"

// test xml config
int test0()
{
	const char *conf_file = "../conf/server_conf_demo.xml";

	tinyxml2::XMLDocument doc;
	if (doc.LoadFile(conf_file) != tinyxml2::XMLError::XML_SUCCESS)
	{
		LOG_ERROR("load conf error %s", conf_file);
		return -1;
	}

	tinyxml2::XMLElement *root = doc.FirstChildElement();
	int server_id = root->IntAttribute("id");
	int server_type = root->IntAttribute("type");
	const char *ip = (char*)root->Attribute("ip");
	int port = root->IntAttribute("port");
	const char *entry_file = (char*)root->Attribute("file");
	LOG_DEBUG("server_id=%d server_type=%d ip=%s port=%d entry_file=%s"
	, server_id, server_type, ip, port, entry_file);

	std::set<std::string> trustIpSet;
	tinyxml2::XMLElement *trust_ip = root->FirstChildElement("trust_ip");
	if (trust_ip)
	{
		tinyxml2::XMLElement *addr = trust_ip->FirstChildElement("address");
		while (addr)
		{
			const char *ip = (char *)addr->Attribute("ip");
			LOG_DEBUG("trust ip=%s", ip);
			trustIpSet.insert(ip);
			addr = addr->NextSiblingElement();
		}
	}

	return 0;
}

// test mysqlmgr
int test1()
{
	std::string host = "127.0.0.1";
	int port = 3306;
	std::string username = "testss";
	std::string password = "123456";
	std::string db_name = "testss";

	MysqlMgr mgr;
	int ret = mgr.Connect(host, port, username, password, db_name);
	if (ret != 0)
	{
		LOG_ERROR("connect fail %d", ret);
		return -1;
	}

	// create
	LOG_DEBUG("******* create user_info");
	const char *sql = "CREATE TABLE IF NOT EXISTS `user_info` (\
		`user_id` bigint(20) NOT NULL AUTO_INCREMENT,\
		`channel_no` int(11) NOT NULL DEFAULT '0',\
		`user_name` varchar(45) NOT NULL DEFAULT '',\
		`user_password` varchar(45) NOT NULL DEFAULT '',\
		`create_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,\
		PRIMARY KEY (`user_id`),\
		KEY `channel_no` (`channel_no`)\
	) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("create table user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}

	LOG_DEBUG("******* create role_summary");
	sql = "CREATE TABLE IF NOT EXISTS `role_summary` (\
		`role_id` bigint(20) NOT NULL AUTO_INCREMENT,\
		`user_id` bigint(20) NOT NULL,\
		`area_no` int(11) NOT NULL,\
		`role_name` varchar(45) NOT NULL,\
		PRIMARY KEY (`role_id`),\
		KEY `user_id` (`user_id`)\
	) ENGINE=InnoDB AUTO_INCREMENT=1000 DEFAULT CHARSET=utf8";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("create table role_summary fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	LOG_DEBUG("");

	
	// insert 1 user
	LOG_DEBUG("******* insert user_info");
	sql = "INSERT INTO user_info (channel_no, user_name, user_password) VALUES (1, 'm1', '123456')";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 1)
	{
		LOG_ERROR("insert user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	LOG_DEBUG("affected rows %d", ret);
	LOG_DEBUG("");

	// insert 2 user
	LOG_DEBUG("******* insert user_info 2");
	sql = "INSERT INTO user_info (channel_no, user_name, user_password) VALUES (1, 'm2', '123456'), (1, 'm3', '123456')";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 2)
	{
		LOG_ERROR("insert user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	LOG_DEBUG("affected rows %d", ret);
	LOG_DEBUG("");

	// duplicate insert, test error
	LOG_DEBUG("******* insert user_info duplicate");
	sql = "INSERT INTO user_info (user_id, channel_no, user_name, user_password) VALUES (,1000, 1, 'm1', '123456')";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != -1)
	{
		LOG_ERROR("insert duplicate fail %d", ret);
		return -1;
	}
	LOG_DEBUG("normal error insert duplicate affected rows %d", ret);
	LOG_DEBUG("normal errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
	LOG_DEBUG("");

	// select user
	{
	LOG_DEBUG("******* select user_info");
	sql = "SELECT * FROM user_info WHERE user_id = 1000";
	ret = mgr.Select(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("select user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	int fieldCount = mgr.FieldCount();
	int numRows = mgr.NumRows();
	LOG_DEBUG("fieldCount=%d numRows=%d", fieldCount, numRows);

	MYSQL_FIELD *pField = mgr.FetchField();
	MYSQL_ROW row;
	while ((row = mgr.FetchRow()) != NULL)
	{
		std::string buffer = "";
		for (int j = 0; j < fieldCount; j++)
		{
			buffer += std::string(pField[j].name) + std::string("=") + std::string(row[j]) + std::string(" ");
		}
		LOG_DEBUG("%s", buffer.c_str());
	}
	LOG_DEBUG("");
	}

	// select multi-user
	{
	LOG_DEBUG("******* select user_info 2");
	sql = "SELECT user_id, channel_no, user_name, user_password FROM user_info WHERE channel_no = 1";
	ret = mgr.Select(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("select user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	int fieldCount = mgr.FieldCount();
	int numRows = mgr.NumRows();
	LOG_DEBUG("fieldCount=%d numRows=%d", fieldCount, numRows);

	MYSQL_FIELD *pField = mgr.FetchField();
	MYSQL_ROW row;
	while ((row = mgr.FetchRow()) != NULL)
	{
		std::string buffer = "";
		for (int j = 0; j < fieldCount; j++)
		{
			buffer += std::string(pField[j].name) + std::string("=") + std::string(row[j]) + std::string(" ");
		}
		LOG_DEBUG("%s", buffer.c_str());
	}
	LOG_DEBUG("");
	}

	// update
	{
	LOG_DEBUG("******* update user_info");
	sql = "UPDATE `user_info` SET user_password='qwerty' WHERE user_id = 1000";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 1)
	{
		LOG_ERROR("update user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	}

	// if (1) return 0;

	// drop
	sql = "DROP TABLE IF EXISTS `user_info`";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("drop table user_info fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}
	
	sql = "DROP TABLE IF EXISTS `role_summary`";
	ret = mgr.Change(sql, strlen(sql));
	if (ret != 0)
	{
		LOG_ERROR("drop table role_summary fail %d", ret);
		LOG_ERROR("errno=%d error=[%s]", mgr.GetErrno(), mgr.GetError());
		return -1;
	}

	mgr.Close();

	return 0;
}

typedef int (*testcase_t) ();
testcase_t test_list[] =
{
	test0
,	test1
};

int main(int argc, char ** argv)
{
	LOG_DEBUG("%s", argv[0]);

	int ret;
	int maxcase;
	int testcase;

	maxcase = sizeof(test_list) / sizeof(testcase_t);
	testcase = maxcase - 1;

	if (argc > 1) {
		if (!strcmp(argv[1], "all"))
		{
			LOG_DEBUG("run all case");
			for (int i=0; i<maxcase; i++)
			{
				printf("\n");
				LOG_DEBUG("run case[%d]", i);
				ret = test_list[i]();
				if (ret != 0) 
				{
					LOG_ERROR("case[%d] ret=%d", i, ret);
					return 0;
				}
			}
			return 0;
		}
		testcase = atoi(argv[1]);
		if (testcase < 0 || testcase >= maxcase) 
		{
			testcase = maxcase - 1;
		}
	}

	LOG_DEBUG("run case[%d]", testcase);
	ret = test_list[testcase]();
	if (ret != 0) 
	{
		LOG_ERROR("case[%d] ret=%d", testcase, ret);
	}

	return 0;
}
