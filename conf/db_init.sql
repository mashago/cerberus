-- call by root
CREATE DATABASE IF NOT EXISTS login_db;
GRANT all on login_db.* to testss@'%' identified by '123456';
GRANT all on login_db.* to testss@'localhost' identified by '123456';

CREATE DATABASE IF NOT EXISTS game_db;
GRANT all on game_db.* to testss@'%' identified by '123456';
GRANT all on game_db.* to testss@'localhost' identified by '123456';

