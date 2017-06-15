
FILE_PATH:=../bin
TARGET:=$(FILE_PATH)/Client

CC:=gcc
CXX:=g++

C_FLAGS:=
CPP_FLAGS:=-O0 -Wall --std=c++11 -g

OS:=$(shell uname -s)
SRC:=$(wildcard *.cpp) $(wildcard *.c)
OBJ:=$(patsubst %.cpp, %.o, $(patsubst %.c, %.o, $(SRC)))

USER_MACROS:=

INC:=../core
LIB_PATH:=../lib
LIB:=core event

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
	$(CXX) $^ -o $@ $(addprefix -L, $(LIB_PATH)) $(addprefix -l, $(LIB))

.PHONY: clean
clean:
	rm -rf $(TARGET) $(OBJ)
