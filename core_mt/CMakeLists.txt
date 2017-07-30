
#1.define target
#2.include
#3.group source
#4.create lib

#1.define target
SET(TARGET_NAME core_mt)

#2.include
INCLUDE_DIRECTORIES(
./
../tinyxml
/usr/local/include/mysql
/usr/include/mysql
)

#3.group source
FILE(GLOB FILES_HEAD *.h *.hpp)
AUX_SOURCE_DIRECTORY(. FILES_SOURCE)
SOURCE_GROUP("Include" FILES ${FILES_HEAD})
SOURCE_GROUP("Source" FILES ${FILES_SOURCE})

#4.create lib
ADD_LIBRARY(${TARGET_NAME} ${FILES_HEAD} ${FILES_SOURCE})
