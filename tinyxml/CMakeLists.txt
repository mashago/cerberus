
#1.define target
#2.include
#3.group source
#4.create lib

#1.define target
SET(TARGET_NAME tinyxml)

#2.include
INCLUDE_DIRECTORIES(
./
)

#3.group source
FILE(GLOB FILES_SOURCE *.h *.hpp *.cpp)
SOURCE_GROUP("source" FILES ${FILES_SOURCE})

#4.create lib
ADD_LIBRARY(${TARGET_NAME} ${FILES_SOURCE})
