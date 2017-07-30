
FILE_PATH:=../bin
TARGET:=$(FILE_PATH)/LuaClient

CC:=gcc
CXX:=g++

C_FLAGS:=
CPP_FLAGS:=-O0 -Wall --std=c++11 -g

OS:=$(shell uname -s)
SRC:=$(wildcard *.cpp) $(wildcard *.c)
OBJ:=$(patsubst %.cpp, %.o, $(patsubst %.c, %.o, $(SRC)))

USER_MACROS:=

INC:=../core_mt ../tinyxml
LIB_PATH:=../lib
LIB:=core_mt tinyxml lua event mysqlclient dl m

ifeq "$(OS)" "Linux"
LIB_PATH+=/usr/lib64/mysql/
endif

ifeq "$(OS)" "Darwin"
LIB_PATH+=/usr/local/mysql/lib
endif

ifeq "$(OS)" "CYGWIN_NT-6.1"
LIB_PATH+=/usr/lib
endif

default: $(TARGET)

info:
	@echo Platform: $(OS)
	@echo SRC: $(SRC)
	@echo OBJ: $(OBJ)

%.o: %.cpp
	$(CXX) $(CPP_FLAGS) $(addprefix -D, $(USER_MACROS)) $(addprefix -I, $(INC)) -c $< -o $@

%.o: %.c
	$(CC) $(C_FLAGS) $(addprefix -D, $(USER_MACROS)) $(addprefix -I, $(INC)) -c $< -o $@

$(TARGET): $(OBJ)
	mkdir -p $(FILE_PATH)
	$(CXX) $(CPP_FLAGS) $^ -o $@ $(addprefix -L, $(LIB_PATH)) $(addprefix -l, $(LIB))

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJ)
