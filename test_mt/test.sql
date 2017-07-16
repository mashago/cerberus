-- call by root
CREATE DATABASE IF NOT EXISTS testss;
GRANT all on testss.* to testss@'%' identified by '123456';
GRANT all on testss.* to testss@'localhost' identified by '123456';

