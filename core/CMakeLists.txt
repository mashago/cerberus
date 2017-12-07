
#1.define target
SET(TARGET_NAME core)

#2.include
INCLUDE_DIRECTORIES(
./
./common
./net
./world
../tinyxml
../lfs
/usr/local/include/mysql
/usr/include/mysql
)

IF(CMAKE_SYSTEM_NAME MATCHES "Darwin")
ELSEIF(CMAKE_SYSTEM_NAME MATCHES "Linux")
ELSEIF(CMAKE_SYSTEM_NAME MATCHES "CYGWIN")
ELSEIF(CMAKE_SYSTEM_NAME MATCHES "Windows")
	INCLUDE_DIRECTORIES(${PROJECT_PATH}/include/windows/lua)
	INCLUDE_DIRECTORIES(${PROJECT_PATH}/include/windows/libevent)
	INCLUDE_DIRECTORIES(${PROJECT_PATH}/include/windows/mysql)
ELSE()
ENDIF()

#3.group source
FILE(GLOB FILES_COMMON common/*.h common/*.hpp common/*.cpp)
FILE(GLOB FILES_NET net/*.h net/*.hpp net/*.cpp)
FILE(GLOB FILES_WORLD world/*.h world/*.hpp world/*.cpp)
SOURCE_GROUP("common" FILES ${FILES_COMMON})
SOURCE_GROUP("net" FILES ${FILES_NET})
SOURCE_GROUP("world" FILES ${FILES_WORLD})

#4.create lib
ADD_LIBRARY(${TARGET_NAME} ${FILES_COMMON} ${FILES_NET} ${FILES_WORLD})
