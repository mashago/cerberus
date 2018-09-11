-- call by root

CREATE DATABASE IF NOT EXISTS mn_game_db1;
-- mysql version below 8.0
GRANT ALL ON mn_game_db1.* TO testmn@'%' IDENTIFIED BY '123456';
GRANT ALL ON mn_game_db1.* TO testmn@'localhost' IDENTIFIED BY '123456';

-- mysql version 8.0 or above
-- CREATE USER IF NOT EXISTS 'testmn'@'%' IDENTIFIED WITH mysql_native_password BY '123456';
-- GRANT ALL ON mn_game_db1.* TO 'testmn'@'%';
